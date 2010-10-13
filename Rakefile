require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

require "rspec"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |t|

end


task :default => ["spec"]

spec = Gem::Specification.new do |s|

  s.name              = "yayimdbs"
  s.version           = "0.1.7"
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

  s.add_dependency("nokogiri", ">= 1.4.2")

  s.add_dependency("activesupport", ">= 3.0.0")
  s.add_dependency("tzinfo", ">= 0.3.22")
  s.add_dependency("i18n", ">= 0.4.1")
  
  s.add_development_dependency("rspec", ">= 1.3.1")

end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec

  # Generate the gemspec file for github.
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

Rake::RDocTask.new do |rd|
  rd.main = "README.md"
  rd.rdoc_files.include("README.md", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end


desc "Re-download imdb sample pages used in specs (Do this when imdb updates)"
task :download_spec_html do
  page_into_file('http://www.imdb.com/title/tt0499549/', 'spec/Avatar.2009.html')
  page_into_file('http://www.imdb.com/title/tt0411008/', 'spec/Lost.2004.html')
  page_into_file('http://www.imdb.com/title/tt0411008/episodes/', 'spec/Lost.2004.Episodes.html')
  page_into_file('http://www.imdb.com/find?s=all&q=starkey+and+hutch', 'spec/starkey_hutch_search.html')
  page_into_file('http://www.imdb.com/media/rm815832320/tt0093437', 'spec/media_page.html')
end

def page_into_file(request_url, file_name)
  require 'net/http'

  file = File.new(file_name, "w")
  file.write(Net::HTTP.get(URI.parse(request_url)))
  file.close

  p "Refreshed #{file_name}"
end
