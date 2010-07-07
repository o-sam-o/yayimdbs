require 'spec_helper'

describe YayImdbs do
  
  context 'should search for movie' do
  
    it 'should find movie imdb id with name and year' do
      movie_name = 'Starsky & Hutch'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      YayImdbs.search_for_imdb_id(movie_name, 2004).should == '0335438'
    
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      YayImdbs.search_for_imdb_id(movie_name, 2003).should == '1380813'
    end

    it 'should find movie imdb id with name only' do
      movie_name = 'Starsky & Hutch'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      YayImdbs.search_for_imdb_id(movie_name, nil).should == '0335438'
    end
  
    it 'should return nil if not matching year' do
      movie_name = 'Starsky & Hutch'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      YayImdbs.search_for_imdb_id(movie_name, 2099).should be_nil
    end  
  
    it 'should find tv show imdb id with name only' do
      movie_name = 'Starsky & Hutch'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      YayImdbs.search_for_imdb_id(movie_name, nil, true).should == '0072567'
    end  
  
    it 'should find the imdb id when search redirects directly to the movie page' do
      movie_name = 'Avatar'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('Avatar.2009.html'))
      YayImdbs.search_for_imdb_id(movie_name, nil, false).should == '0499549'
    end  

    it 'should not find result if incorrect video type' do
      movie_name = 'Avatar'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('Avatar.2009.html'))
      # We want a tv show but a movie is returned
      YayImdbs.search_for_imdb_id(movie_name, nil, true).should be_nil
    end

    it 'should search imdb and return name, year and id' do
      movie_name = 'Starsky & Hutch'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('starkey_hutch_search.html'))
      search_results = YayImdbs.search_imdb(movie_name)
    
      search_results.should == [{:name => 'Starsky & Hutch', :year => 2004, :imdb_id => '0335438', :video_type => :movie},
                    {:name => 'Starsky and Hutch', :year => 1975, :imdb_id => '0072567', :video_type => :tv_show},
                    {:name => 'Starsky & Hutch', :year => 2003, :imdb_id => '1380813', :video_type => :movie},
                    {:name => 'Starsky & Hutch: A Last Look', :year => 2004, :imdb_id => '0488639', :video_type => :movie},
                    {:name => 'Starsky & Hutch Documentary: The Word on the Street', :year => 1999, :imdb_id => '1393834', :video_type => :tv_show},
                    {:name => 'TV Guide Specials: Starsky & Hutch', :year => 2004, :imdb_id => '0464230', :video_type => :tv_show},
                    {:name => "He's Starsky, I'm Hutch", :year => 2004, :imdb_id => '1540121', :video_type => :tv_show},
                    {:name => 'The Real Story of Butch Cassidy and the Sundance Kid', :year => 1993, :imdb_id => '0401745', :video_type => :movie},
                    {:name => "Le boucher, la star et l'orpheline", :year => 1975, :imdb_id => '0069819', :video_type => :movie},
                    {:name => "Hutch Stirs 'em Up", :year => 1923, :imdb_id => '0290216', :video_type => :movie},
                    {:name => 'Love and Hate: The Story of Colin and Joanne Thatcher', :year => 1989, :imdb_id => '0097788', :video_type => :tv_show}]                                    
    end  

    it 'should search imdb and return name, year and id even for exact search result' do
      movie_name = 'Avatar'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('Avatar.2009.html'))
    
      YayImdbs.search_imdb(movie_name).should == [{:name => 'Avatar', :year => 2009, :imdb_id => '0499549', :video_type => :movie}]               
    end

    it 'should search imdb and return name, year and id even for exact tv show search result' do
      movie_name = 'Lost'
      YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(stubbed_page_result('Lost.2004.html'))
      YayImdbs.search_imdb(movie_name).should == [{:name => 'Lost', :year => 2004, :imdb_id => '0411008', :video_type => :tv_show}]                
    end
  
  end
  
  context 'should determine content type' do
  
    it 'should detect tv show type' do
      imdb_id = '0411008'
      YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(stubbed_page_result('Lost.2004.html'))
      YayImdbs.should_receive(:get_episodes_page).with(imdb_id).and_return(stubbed_page_result('Lost.2004.Episodes.html'))
    
      YayImdbs.scrap_movie_info(imdb_id)['video_type'].should == :tv_show
    end  
  
    it 'should detect movie type' do
      imdb_id = '0499549'
      YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(stubbed_page_result('Avatar.2009.html'))
    
      YayImdbs.scrap_movie_info(imdb_id)['video_type'].should == :movie
    end  

  end
  
  context 'should scrap info from imdb' do
  
    it 'should retrive the metadata for a movie' do
      imdb_id = '0499549'
      YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(stubbed_page_result('Avatar.2009.html'))
      movie_info = YayImdbs.scrap_movie_info(imdb_id)
      
      movie_info[:title].should == 'Avatar'
      movie_info[:year].should == 2009
      movie_info[:video_type].should == :movie
      movie_info[:release_date].should == Date.new(y=2009,m=12,d=17)
      movie_info[:plot].should == 'A paraplegic marine dispatched to the moon Pandora on a unique mission becomes torn between following his orders and protecting the world he feels is his home.'
      movie_info[:director].should == 'James Cameron'
      movie_info[:tagline].should == 'Enter the World'
      # TODO should be a list, see below
      movie_info[:language].should == 'English'
      movie_info[:runtime].should == 162
      movie_info[:genre].should == ['Action', 'Adventure', 'Sci-Fi']
    end  
  
    it 'should retrieve metadata for a tv show' do
      imdb_id = '0411008'
      YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(stubbed_page_result('Lost.2004.html'))
      YayImdbs.should_receive(:get_episodes_page).with(imdb_id).and_return(stubbed_page_result('Lost.2004.Episodes.html'))
      show_info = YayImdbs.scrap_movie_info(imdb_id)
      
      show_info[:title].should == 'Lost'
      show_info[:year].should == 2004
      show_info[:video_type].should == :tv_show
      show_info[:plot].should == 'The survivors of a plane crash are forced to live with each other on a remote island, a dangerous new world that poses unique threats of its own.'
      show_info[:tagline].should == "They're not the survivors they think they are. (Season Two)"
      # TODO should be a list, see below
      show_info[:language].should == 'English'
      show_info[:runtime].should == 42
      show_info[:genre].should == ['Adventure', 'Drama', 'Mystery', 'Sci-Fi', 'Thriller']      
      
      show_info[:episodes].should_not be_nil
      show_info[:episodes].should_not be_empty
      show_info[:episodes].length.should == 116
      
      series_2_ep_5 = nil
      show_info[:episodes].each do |episode|
        episode[:series].should_not be_nil
        episode[:episode].should_not be_nil
        episode[:title].should_not be_nil
        episode[:date].should_not be_nil

        series_2_ep_5 = episode if episode[:series] == 2 && episode[:episode] == 5
      end      
      
      series_2_ep_5[:title].should == '...And Found'
      series_2_ep_5[:plot].should == %q{A desperate and growingly insane Michael sets off into the jungle by himself determined to find Walt, but discovers that he is not alone. Meanwhile, Sawyer and Jin are ordered by their captors, the tail crash survivors, to take them to their camp. But they are delayed when Jin and the hulking Mr. Eko are forced to go into the jungle to look for Michael before the dreaded "others" find him first. Back at the beach camp, Sun frantically searches for her missing wedding ring which triggers flashbacks to Sun and Jin's past showing how they met for the first time in early 1990s Seoul, when Jin was working as a doorman of a fancy hotel where Sun was staying at for a courtship engagement set up by her mother.}
      series_2_ep_5[:date].should == Date.new(y=2005,m=10,d=19)
    end  
  
    it 'should be possible to access movie info by string or symbol' do
      imdb_id = '0499549'
      YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(stubbed_page_result('Avatar.2009.html'))
      movie_info = YayImdbs.scrap_movie_info(imdb_id)
      
      movie_info['title'].should == 'Avatar'
      
      movie_info[:title].should == 'Avatar'
    end
  
    it 'should return a list of languages for a movie' do
      pending
    end  
  
  end  
  
  def stubbed_page_result(stub_file)
    open(File.join(File.dirname(__FILE__), stub_file)) { |f| Nokogiri::HTML(f) }
  end
end