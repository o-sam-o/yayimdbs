# encoding: UTF-8
require 'open-uri'
require 'nokogiri'

begin
  # Rails 3
  require 'active_support/core_ext/object'
  require 'active_support/core_ext/hash/indifferent_access.rb'
rescue
  # Rails 2.3
  require 'active_support/all'
end

class YayImdbs 
  IMDB_BASE_URL = 'http://www.imdb.com/'
  IMDB_SEARCH_URL = IMDB_BASE_URL + 'find?s=tt&q='
  IMDB_MOVIE_URL = IMDB_BASE_URL + 'title/tt'

  STRIP_WHITESPACE = /(\s{2,}|\n|\||\302\240\302\273)/u

  DATE_PROPERTIES = [:release_date]
  LIST_PROPERTIES = [:genres, :plot_keywords, :country, :sound_mix, :language]
  INT_LIST_PROPERTIES = [:year, :season]
  PROPERTY_ALIAS  = {:genres => :genre, :taglines => :tagline, :year => :years, :season => :seasons, :motion_picture_rating_mpaa => :mpaa}

  class << self

    def search_for_imdb_id(name, year=nil, type=nil)
      search_results = self.search_imdb(name)

      search_results.each do |result|
        # Ensure result is the correct video type
        next if type && (result[:video_type] != type)

        # If no year provided just return first result
        return result[:imdb_id] if year.nil? || result[:year] == year
      end
      return nil
    end

    def search_imdb(search_term)
      search_results = []
    
      doc = self.get_search_page(search_term)

      # If the search is an exact match imdb will redirect to the movie page not search results page
      # we uses the title meta element to determine if we got an exact match
      movie_title, movie_year = get_title_and_year_from_meta(doc)
      if movie_title
        canonical_link = doc.at_css("link[rel='canonical']").try(:[], 'href')
        if canonical_link && canonical_link =~ /tt(\d+)\//
          return [:name => movie_title, :year => movie_year, :imdb_id => $1, :video_type => video_type_from_meta(doc)]
        else
          raise "Unable to extract imdb id from exact search result"
        end
      end
    
      doc.css("td").each do |td| 
        td.css("a").each do |link|
          href = link['href']
          current_name = link.content

          # Ignore links with no text (e.g. image links) or links that don't link to movie pages
          next unless current_name.present? && href =~ /^\/title\/tt(\d+)/
          imdb_id = $1
          current_year = $1.gsub(/\(\)/, '').to_i if td.inner_text =~ /\((\d{4}\/?\w*)\)/
          search_results << {:imdb_id => imdb_id, :name => clean_title(current_name), :year => current_year, :video_type => video_type(td)}
        end
      end
    
      return search_results
    end  

    def scrap_movie_info(imdb_id)
      info_hash = {:imdb_id => imdb_id}.with_indifferent_access
    
      doc = self.get_movie_page(imdb_id)
      title, year = get_title_and_year_from_meta(doc)
      info_hash[:title], info_hash[:year] = title, year
      if info_hash['title'].nil?
        #If we cant get title and year something is wrong
        raise "Unable to find title or year for imdb id #{imdb_id}"
      end
      info_hash[:video_type] = self.video_type_from_meta(doc)
      
      info_hash[:plot] = doc.xpath("//td[@id='overview-top']/p[2]").inner_text.strip

      found_info_divs = false
      movie_properties(doc) do |key, value| 
        found_info_divs = true
        if DATE_PROPERTIES.include?(key)
          begin
            value = Date.strptime(value, '%d %B %Y')
          rescue 
            info_hash["raw_#{key}"] = value
            value = nil
          end
         elsif key == :runtime
          if value =~ /(\d+)\smin/
            value = $1.to_i
          else
            info_hash[:raw_runtime] = value
            value = nil
          end
        elsif LIST_PROPERTIES.include?(key)
          value = value.split('|').collect { |l| l.gsub(/[^a-zA-Z0-9\-]/, '') }
        elsif INT_LIST_PROPERTIES.include?(key)
          value = value.split('|').collect { |l| l.strip.to_i }.reject { |y| y <= 0 }
        end
        info_hash[key] = value
        info_hash[PROPERTY_ALIAS[key]] = value if PROPERTY_ALIAS[key]
      end
      # Hack tv shows can have a year property, which is a list, fixing ...
      info_hash[:year] = year

      if not found_info_divs
        #If we don't find any info divs assume parsing failed
        raise "No info divs found for imdb id #{imdb_id}"
      end

      self.scrap_images(doc, info_hash)

      #scrap episodes if tv series
      if info_hash.has_key?('season')
        self.scrap_episodes(info_hash)
      end

      return info_hash
    end

    def movie_properties(doc)
      doc.xpath("//div/h4").each do |h4|
        div = h4.parent
        raw_key = h4.inner_text
        key = raw_key.sub(':', '').strip.downcase
        value = div.inner_text[((div.inner_text =~ /#{Regexp.escape(raw_key)}/) + raw_key.length).. -1]
        value = value.gsub(/\302\240\302\273/u, '').strip.gsub(/(See more)|(see all)|(See all certifications)$/, '').strip

        symbol_key = key.downcase.gsub(/[^a-zA-Z0-9 ]/, '').gsub(/\s/, '_').to_sym

        yield symbol_key, value
      end
    end

     def scrap_images(doc, info_hash)
      #scrap poster image urls
      thumb = doc.xpath("//td[@id = 'img_primary']/a/img")
      if thumb.first
        thumbnail_url = thumb.first['src']
        if not thumbnail_url =~ /\/nopicture\// 
          info_hash['medium_image'] = thumbnail_url

          # Small thumbnail image, gotten by hacking medium url
          info_hash['small_image'] = thumbnail_url.sub(/@@.*$/, '@@._V1._SX120_120,160_.jpg')

          #Try to scrap a larger version of the image url
          large_img_page = doc.xpath("//td[@id = 'img_primary']/a").first['href']
          large_img_doc = self.get_media_page(large_img_page) 
          large_img_url = large_img_doc.xpath("//img[@id = 'primary-img']").first['src'] unless large_img_doc.xpath("//img[@id = 'primary-img']").empty?
          info_hash['large_image'] = large_img_url
        end
      end
     end

     def scrap_episodes(info_hash)
        episodes = []
        doc = self.get_episodes_page(info_hash[:imdb_id])

        doc.css(".filter-all").each do |e_div|
          if e_div.at_css('h3').inner_text =~ /Season (\d+), Episode (\d+):/
            episode = {"series" => $1.to_i, "episode" => $2.to_i, "title" => $'.strip}

            raw_date = e_div.at_css('strong').inner_text.strip
            episode['date'] = Date.parse(raw_date) rescue nil
            if e_div.inner_text =~ /#{raw_date}/
              episode['plot'] = $'.strip
            end

            episodes << episode
          end
        end
        info_hash['episodes'] = episodes
     end

      def get_search_page(name)
        Nokogiri::HTML(open(IMDB_SEARCH_URL + URI.escape(name)))
      end

      def get_movie_page(imdb_id)
        Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id))
      end

      def get_episodes_page(imdb_id)
        Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id + '/episodes'))
      end

      def get_media_page(url_fragment)
        Nokogiri::HTML(open(IMDB_BASE_URL + url_fragment))
       end

      def get_title_and_year_from_meta(doc)
        title_text = doc.at_css("meta[name='title']").try(:[], 'content')
        # Matches 'Movie Name (2010)' or 'Movie Name (2010/I)' or 'Lost (TV Series 2004–2010)'
        if title_text && title_text =~ /(.*) \([^\)0-9]*(\d{4})((\/\w*)|(.\d{4}))?\)/
          movie_title = self.clean_title($1)
          movie_year = $2.to_i
        end
        return movie_title, movie_year
      end  

      # Remove surrounding double quotes that seems to appear on tv show name
      def clean_title(movie_title)
        movie_title = $1 if movie_title =~ /^"(.*)"$/
        return movie_title.strip
      end  
    
      # Hackyness to get around ruby 1.9 encoding issue
      def strip_whitespace(s)
        s.encode('UTF-8').gsub(STRIP_WHITESPACE, '').strip
      end  
    
      def video_type(td)
        return :tv_show if td.content =~ /\((TV series|TV)\)/
        return :movie
      end 
    
      def video_type_from_meta(doc)
        type_text = doc.at_css("meta[property='og:type']").try(:[], 'content')
        type_text == 'tv_show' ? :tv_show : :movie
      end

    end
end
