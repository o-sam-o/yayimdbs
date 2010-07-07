require 'spec_helper'

describe YayImdbs do
  
  it 'should find movie imdb id with name and year' do
    movie_name = 'Starsky & Hutch'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, 2004).should == '0335438'
    
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, 2003).should == '1380813'
  end

  it 'should find movie imdb id with name only' do
    movie_name = 'Starsky & Hutch'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, nil).should == '0335438'
  end
  
  it 'should return nil if not matching year' do
    movie_name = 'Starsky & Hutch'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, 2099).should be_nil
  end  
  
  it 'should find tv show imdb id with name only' do
    movie_name = 'Starsky & Hutch'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, nil, true).should == '0072567'
  end  
  
  it 'should find the imdb id when search redirects directly to the movie page' do
    movie_name = 'Avatar'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'Avatar.2009.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_for_imdb_id(movie_name, nil, false).should == '0499549'
  end  

  it 'should not find result if incorrect video type' do
    movie_name = 'Avatar'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'Avatar.2009.html')) { |f| Nokogiri::HTML(f) })
    # We want a tv show but a movie is returned
    YayImdbs.search_for_imdb_id(movie_name, nil, true).should be_nil
  end

  it 'should search imdb and return name, year and id' do
    movie_name = 'Starsky & Hutch'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'starkey_hutch_search.html')) { |f| Nokogiri::HTML(f) })
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
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'Avatar.2009.html')) { |f| Nokogiri::HTML(f) })
    
    YayImdbs.search_imdb(movie_name).should == [{:name => 'Avatar', :year => 2009, :imdb_id => '0499549', :video_type => :movie}]               
  end

  it 'should search imdb and return name, year and id even for exact tv show search result' do
    movie_name = 'Lost'
    YayImdbs.should_receive(:get_search_page).with(movie_name).and_return(open(File.join(File.dirname(__FILE__), 'Lost.2004.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.search_imdb(movie_name).should == [{:name => 'Lost', :year => 2004, :imdb_id => '0411008', :video_type => :tv_show}]                
  end
  
  it 'should detect tv show type' do
    imdb_id = '0411008'
    YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(open(File.join(File.dirname(__FILE__), 'Lost.2004.html')) { |f| Nokogiri::HTML(f) })
    YayImdbs.should_receive(:get_episodes_page).with(imdb_id).and_return(open(File.join(File.dirname(__FILE__), 'Lost.2004.Episodes.html')) { |f| Nokogiri::HTML(f) })
    
    YayImdbs.scrap_movie_info(imdb_id)['video_type'].should == :tv_show
  end  
  
  it 'should detect movie type' do
    imdb_id = '0499549'
    YayImdbs.should_receive(:get_movie_page).with(imdb_id).and_return(open(File.join(File.dirname(__FILE__), 'Avatar.2009.html')) { |f| Nokogiri::HTML(f) })
    
    YayImdbs.scrap_movie_info(imdb_id)['video_type'].should == :movie
  end  

end