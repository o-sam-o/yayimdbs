require "rubygems"

#require "rake/gempackagetask"
require "rubygems/package_task"

#require "rake/rdoctask"
require "rdoc/task"

require "rspec"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |t|

end


task :default => ["spec"]

desc 'create gemspec file'
task :gemspec do
  gemspec = Gem::Specification.new do |s|

    s.name              = "yayimdbs"
    s.version           = "0.2.8"
    s.summary           = "Yet Another Ying IMDB Scraper"
    s.description       = "A simple imdb scraper built on Nokogiri for ruby 1.9+"
    s.author            = "Sam Cavenagh"
    s.email             = "cavenaghweb@hotmail.com"
    s.homepage          = "http://github.com/o-sam-o/yayimdbs"

    s.has_rdoc          = true
    s.extra_rdoc_files  = %w(README.md)
    s.rdoc_options      = %w(--main README.md)

    s.files             = %w(README.md) + Dir.glob("{spec,lib/**/*}")
    s.require_paths     = ["lib"]

    s.add_runtime_dependency("nokogiri", "~> 1.4", ">= 1.4.2")
    s.add_runtime_dependency("activesupport")
    s.add_runtime_dependency("i18n")

    s.add_development_dependency("rspec", ">= 2.0.0")

  end

  Gem::PackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec

    # Generate the gemspec file for github.
    file = File.dirname(__FILE__) + "/#{gemspec.name}.gemspec"
    File.open(file, "w") {|f| f << gemspec.to_ruby }
  end
end

RDoc::Task.new do |rd|
  rd.main = "README.md"
  rd.rdoc_files.include("README.md", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{gemspec.name}.gemspec"
end


desc "Re-download imdb sample pages used in specs (Do this when imdb updates)"
task :download_spec_html do
  page_into_file('http://www.imdb.com/title/tt0499549/', 'spec/Avatar.2009.html')
  page_into_file('http://www.imdb.com/title/tt0411008/', 'spec/Lost.2004.html')
  page_into_file('http://www.imdb.com/title/tt0411008/episodes', 'spec/Lost.2004.Episodes.html')
  (1..6).to_a.each do |season|
    page_into_file("http://www.imdb.com/title/tt0411008/episodes?season=#{season}", "spec/Lost.2004.Episodes.Season.#{season}.html")
  end
  page_into_file('http://www.imdb.com/find?s=all&q=Starsky+%26+Hutch', 'spec/starkey_hutch_search.html')
  page_into_file('http://www.imdb.com/media/rm815832320/tt0093437', 'spec/media_page.html')
  page_into_file('http://www.imdb.com/title/tt0499549/officialsites', 'spec/avatar_officialsites.html')
  page_into_file('http://www.imdb.com/title/tt1517155/', 'spec/avatar_game.html')
end

def page_into_file(request_url, file_name)
  require 'net/http'

  uri = URI.parse(request_url)
  req = Net::HTTP::Get.new(uri)
  # avoid localized results when calling this from non-US countries:
  req['Accept-Language'] = 'en-US,en;q=0.5'

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  if res.is_a?(Net::HTTPSuccess)
    file = File.new(file_name, "w")
    file.write(res.body)
    file.close
  end

  p "Refreshed #{file_name}"
end
