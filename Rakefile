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
  s.version           = "0.1.4"
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

  s.add_dependency("activesupport", ">= 3.0.0.beta4")
  s.add_dependency("tzinfo", ">= 0.3.22")
  s.add_dependency("i18n", ">= 0.4.1")
  
  s.add_development_dependency("rspec", ">= 2.5.8")

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

desc "Run all specs with RCov"
Spec::Rake::SpecTask.new('specs_with_coverage') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--include', 'lib']
end

