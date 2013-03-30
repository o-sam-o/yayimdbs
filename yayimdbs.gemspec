# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "yayimdbs"
  s.version = "0.2.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sam Cavenagh"]
  s.date = "2013-03-30"
  s.description = "A simple imdb scraper built on Nokogiri for ruby 1.9+"
  s.email = "cavenaghweb@hotmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "spec", "lib/yay_imdbs.rb", "lib/yayimdbs.rb"]
  s.homepage = "http://github.com/o-sam-o/yayimdbs"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Yet Another Ying IMDB Scraper"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.2"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 2.0.0"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 2.0.0"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 2.0.0"])
  end
end
