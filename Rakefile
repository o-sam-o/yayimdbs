require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

require "spec"
require "spec/rake/spectask"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = %w(--format specdoc --colour)
  t.libs = ["spec"]
end


task :default => ["spec"]

spec = Gem::Specification.new do |s|

  s.name              = "yayimdbs"
  s.version           = "0.1.0"
  s.summary           = "Yet Another Ying IMDB Scraper"
  s.author            = "Sam Cavenagh"
  s.email             = "cavenaghweb@hotmail.com"
  s.homepage          = "http://github.com/o-sam-o/yayimdbs"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)

  s.files             = %w(README.md) + Dir.glob("{spec,lib/**/*,img/*}")
  s.require_paths     = ["lib"]

  s.add_dependency("hpricot")
  s.add_dependency("htmlentities")
  
  s.add_development_dependency("rspec")

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
