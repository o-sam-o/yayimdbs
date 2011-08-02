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

  MORE_INFO_LINKS = ['See more',
                     'Add/edit official sites',
                     'See all certifications',
                     'See full summary',
                     'see all',
                    ]

  DATE_PROPERTIES = [:release_date]
  LIST_PROPERTIES = [:genres, :plot_keywords, :country, :sound_mix, :language]
  INT_LIST_PROPERTIES = [:year, :season]
  PROPERTY_ALIAS  = {:genres => :genre, 
                     :taglines => :tagline, 
                     :year => :years, 
                     :season => :seasons,
                     :language => :languages,
                     :motion_picture_rating_mpaa => :mpaa,
					 :official_sites => :official_site}

  class << self

    def search_for_imdb_id(name, year=nil, type=nil)
      search_results = search_imdb(name)

      search_results.each do |result|
        # Ensure result is the correct video type
        next if type && (result[:video_type].to_s != type.to_s)

        # If no year provided just return first result
        return result[:imdb_id] if year.nil? || result[:year] == year
      end
      return nil
    end

    def search_imdb(search_term)
      search_results = []
    
      doc = get_search_page(search_term)

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
    
      doc = get_movie_page(imdb_id)
      title, year = get_title_and_year_from_meta(doc)
      info_hash[:title], info_hash[:year] = title, year
      if info_hash['title'].nil?
        #If we cant get title and year something is wrong
        raise "Unable to find title or year for imdb id #{imdb_id}"
      end
      info_hash[:video_type] = video_type_from_meta(doc)
      
      info_hash[:plot] = doc.xpath("//td[@id='overview-top']/p[2]").inner_text.strip
      info_hash[:rating] = doc.at_css('.rating-rating').content.gsub(/\/.*/, '').to_f rescue nil

      found_info_divs = false
      movie_properties(doc) do |key, value|
        found_info_divs = true
        info_hash["raw_#{key}"] = value
        info_hash[key] = clean_movie_property(key, value, imdb_id)
        info_hash[PROPERTY_ALIAS[key]] = info_hash[key] if PROPERTY_ALIAS[key]
      end

      unless found_info_divs
        #If we don't find any info divs assume parsing failed
        raise "No info divs found for imdb id #{imdb_id}"
      end

      # Hack: tv shows can have a year property, which is a list, fixing ...
      info_hash[:year] = year

      scrap_images(doc, info_hash)

      #scrap episodes if tv series
      scrap_episodes(info_hash) if info_hash.has_key?('season')

      return info_hash
    end

    def clean_movie_property(key, value, imdb_id)
      if DATE_PROPERTIES.include?(key)
        value = Date.strptime(value, '%d %B %Y') rescue nil
      elsif key == :runtime
        if value =~ /(\d+)\smin/
          value = $1.to_i
        else
          value = nil
        end
      elsif key == :official_sites
        value = get_official_site_url(value, imdb_id)
      elsif LIST_PROPERTIES.include?(key)
        value = value.split('|').collect { |l| l.gsub(/[^a-zA-Z0-9\-]/, '') }
      elsif INT_LIST_PROPERTIES.include?(key)
        value = value.split('|').collect { |l| l.strip.to_i }.reject { |y| y <= 0 }
      end
      return value
    end

    def movie_properties(doc)
      doc.css("div h4").each do |h4|
        div = h4.parent
        raw_key = h4.inner_text
        key = raw_key.sub(':', '').strip.downcase
        value = div.inner_text[((div.inner_text =~ /#{Regexp.escape(raw_key)}/) + raw_key.length).. -1]
        value = value.gsub(/\302\240\302\273/u, '').strip.gsub(/(#{MORE_INFO_LINKS.join(')|(')})$/i, '').strip
        symbol_key = key.downcase.gsub(/[^a-zA-Z0-9 ]/, '').gsub(/\s/, '_').to_sym
        yield symbol_key, value
      end
    end

    # TODO capture all official sites, not all sites have an "Official site" link (e.g. Lost)
    def get_official_site_url(value, imdb_id)
        value = value.match(/<a href="(.*?)">Official site<\/a>/)
        if value.nil?
            value = get_official_sites_page(imdb_id).inner_html.match(/<a href="(.*?)">Official site<\/a>/)
        end
        return $1
    end

    def scrap_images(doc, info_hash)
      #scrap poster image urls
      thumbnail_url = doc.at_css("td[id=img_primary] a img").try(:[], 'src')
      return if thumbnail_url.nil? || thumbnail_url =~ /\/nopicture\//

      info_hash['medium_image'] = thumbnail_url
      # Small thumbnail image, gotten by hacking medium url
      info_hash['small_image'] = thumbnail_url.sub(/@@.*$/, '@@._V1._SX120_120,160_.jpg')

      #Try to scrap a larger version of the image url
      large_img_page_link = doc.at_css("td[id=img_primary] a").try(:[], 'href')
      return unless large_img_page_link
      large_img_doc = get_media_page(large_img_page_link) 
      large_img_url = large_img_doc.at_css("img[id=primary-img]").try(:[], 'src')
      info_hash['large_image'] = large_img_url
    end

    def scrap_episodes(info_hash)
      episodes = []
      doc = get_episodes_page(info_hash[:imdb_id])

      doc.css(".filter-all").each do |e_div|
        next unless e_div.at_css('h3').inner_text =~ /Season (\d+), Episode (\d+):/
          episode = {"series" => $1.to_i, "episode" => $2.to_i, "title" => $'.strip}

        raw_date = e_div.at_css('strong').inner_text.strip
        episode['date'] = Date.parse(raw_date) rescue nil

        # Seems that the day can sometimes be ???? which doesnt play will with regex
        episode['plot'] = $'.strip if e_div.inner_text =~ /#{raw_date}/ rescue nil

        episodes << episode
      end
      info_hash['episodes'] = episodes
    end

      def get_search_page(name)
        Nokogiri::HTML(open(IMDB_SEARCH_URL + URI.escape(name)))
      end

      def get_movie_page(imdb_id)
        Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id))
      end
	  
      def get_official_sites_page(imdb_id)
        Nokogiri::HTML(open(IMDB_MOVIE_URL + imdb_id + '/officialsites'	))
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
          movie_title = clean_title($1)
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
