# encoding: utf-8
require 'open-uri'
require 'nokogiri'
require 'htmlentities'
require 'activesupport'

class YayImdbs 
  IMDB_BASE_URL = 'http://www.imdb.com/'
  IMDB_SEARCH_URL = IMDB_BASE_URL + 'find?s=tt&q='
  IMDB_MOVIE_URL = IMDB_BASE_URL + 'title/tt'

  STRIP_WHITESPACE = /(\s{2,}|\n|\||\302\240\302\273)/

  def self.search_for_imdb_id(name, year, tv_series=false)
    search_results = self.search_imdb(name)
    return nil if search_results.empty?
  
    search_results.each do |result|
      # Ensure result is the correct video type
      next if (result[:video_type] == :tv_show) != tv_series
    
      # If no year provided just return first result
      return result[:imdb_id] if !year || result[:year] == year
    end
    return nil  
  end

  def self.search_imdb(search_term)
    search_results = []
  
    doc = self.get_search_page(search_term)
    # If the search is an exact match imdb will redirect to the movie page not search results page
    # we uses the the title meta element to determine if we got an exact match
    movie_title, movie_year = get_title_and_year_from_meta(doc)
    if movie_title
      canonical_link = doc.xpath("//link[@rel='canonical']")
      if canonical_link && canonical_link.first['href'] =~ /tt(\d+)\//
        return [:name => movie_title, :year => movie_year, :imdb_id => $1, :video_type => self.video_type_from_meta(doc)]
      else
        raise "Unable to extract imdb id from exact search result"
      end
    end
  
    coder = HTMLEntities.new
    doc.xpath("//td").each do |td| 
      td.xpath(".//a").each do |link|  
        href = link['href']
        current_name = link.content
        
        # Ignore links with no text (e.g. image links)
        next unless current_name.present?
        current_name = self.clean_title(coder.decode(current_name))
      
        if href =~ /^\/title\/tt(\d+)/
          imdb_id = $1
          current_year = $1.gsub(/\(\)/, '').to_i if td.inner_text =~ /\((\d{4}\/?\w*)\)/
          search_results << {:imdb_id => imdb_id, :name => current_name, :year => current_year, :video_type => self.video_type(td)}
        end
      end
    end
  
    return search_results
  end  

  def self.scrap_movie_info(imdb_id)
    info_hash = HashWithIndifferentAccess.new
  
    doc = self.get_movie_page(imdb_id)
    coder = HTMLEntities.new
    info_hash['title'], info_hash['year'] = get_title_and_year_from_meta(doc)
    if info_hash['title'].nil?
      #If we cant get title and year something is wrong
      raise "Unable to find title or year for imdb id #{imdb_id}"
    end
    info_hash['video_type'] = self.video_type_from_meta(doc)
    
    found_info_divs = false
    doc.xpath("//div[@class='info']").each do |div|
      next if div.xpath(".//h5").empty?
      found_info_divs = true
      key = div.xpath(".//h5").first.inner_text.sub(':', '').downcase
      value_search = ".//div[@class = 'info-content']"
      # Try to only get text values and ignore links as some info blocks have a "click for more info" type link at the end
      value = div.xpath(value_search).first.children.map{|e| e.text? ? e.to_s.encode("UTF-8") : ''}.join.gsub(STRIP_WHITESPACE, '').strip
      if value.empty?
        value = div.xpath(value_search).first.content.gsub(STRIP_WHITESPACE, '')
      end
      value = coder.decode(value)
      if key == 'release date'
        begin
          value = Date.strptime(value, '%d %B %Y')
        rescue 
          p "Invalid date '#{value}' for imdb id: #{imdb_id}"
          value = nil
        end
      elsif key == 'runtime'
        if value =~ /(\d+)\smin/
          value = $1.to_i
        else
          p "Unexpected runtime format #{value} for movie #{imdb_id}"
        end
      elsif key == 'genre'
        value = value.sub(/(See more$)|(more$)/, '').strip.split
      elsif key == 'language'
        # This is a bit of a hack, I dont really want to deal with multiple langauges, so if there is more than one
        # just use english or the first one found
        value = nil
        div.xpath(value_search).first.inner_text.split(/\|/).collect {|l| l.strip}.each do |language|
          value = language if value.nil?
          value = language if language.downcase == 'english'
        end
      end
      info_hash[key.downcase.gsub(/\s/, '_')] = value
    end
  
    if not found_info_divs
      #If we don't find any info divs assume parsing failed
      raise "No info divs found for imdb id #{imdb_id}"
    end
  
  
    #scrap poster image urls
    thumb = doc.xpath("//div[@class = 'photo']/a/img")
    if thumb
      thumbnail_url = thumb.first['src']
      if not thumbnail_url =~ /addposter.jpg$/ 
        info_hash['small_image'] = thumbnail_url
      
        #Try to scrap a larger version of the image url
        large_img_page = doc.xpath("//div[@class = 'photo']/a").first['href']
        large_img_doc = Nokogiri::HTML(open('http://www.imdb.com' + large_img_page))
        large_img_url = large_img_doc.xpath("//img[@id = 'primary-img']").first['src'] unless large_img_doc.xpath("//img[@id = 'primary-img']").empty?
        info_hash['large_image'] = large_img_url
      end
    end
  
    #scrap episodes if tv series
    if info_hash.has_key?('seasons')
      episodes = []
      doc = self.get_episodes_page(imdb_id)
      episode_divs = doc.css(".filter-all")
      episode_divs.each do |e_div|
        if e_div.xpath('.//h3').inner_text =~ /Season (\d+), Episode (\d+):/
          episode = {"series" => $1.to_i, "episode" => $2.to_i, "title" => coder.decode($').strip}
          if e_div.xpath(".//td").inner_text =~ /(\d+ (January|February|March|April|May|June|July|August|September|October|November|December) \d{4})/
            episode['date'] = Date.parse($1)
            episode['plot'] = coder.decode($').strip
          end
          episodes << episode
        end
      end
      info_hash['episodes'] = episodes
    end
  
    return info_hash 
  end

  private
    def self.get_search_page(name)
      return Nokogiri::HTML(open(IMDB_SEARCH_URL + URI.escape(name)))
    end

    def self.get_movie_page(imdb_id)
      return Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id))
    end

    def self.get_episodes_page(imdb_id)
      return Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id + '/episodes'))
    end

    def self.get_title_and_year_from_meta(doc)
      return nil, nil unless doc.xpath("//meta[@name='title']").first
    
      title_text = doc.xpath("//meta[@name='title']").first['content']
      # Matches 'Movie Name (2010)' or 'Movie Name (2010/I)'
      if title_text =~ /(.*) \((\d{4})\/?\w*\)/
        coder = HTMLEntities.new
        movie_title = coder.decode($1)
        movie_year = $2.to_i
      
        movie_title = self.clean_title(movie_title)
      end
      return movie_title, movie_year
    end  

    # Remove surrounding double quotes that seems to appear on tv show name
    def self.clean_title(movie_title)
      movie_title = $1 if movie_title =~ /^"(.*)"$/
      return movie_title.strip
    end  
  
    def self.video_type(td)
      return :tv_show if td.content =~ /\((TV series|TV)\)/
      return :movie
    end 
  
    def self.video_type_from_meta(doc)
      meta_type_tag = doc.xpath("//meta[contains(@property,'type')]")
      return :movie unless meta_type_tag.first
      type_text = meta_type_tag.first['content']
      case type_text
        when 'tv_show' then return :tv_show
        else return :movie
      end   
    end
end