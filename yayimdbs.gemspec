# -*- encoding: utf-8 -*-
# stub: yayimdbs 0.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "yayimdbs"
  s.version = "0.2.8"
  s.license = "MIT"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Sam Cavenagh"]
  s.date = "2016-07-03"
  s.description = "A simple imdb scraper built on Nokogiri for ruby 1.9+"
  s.email = "cavenaghweb@hotmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "lib/yay_imdbs.rb", "lib/yayimdbs.rb", "spec"]
  s.homepage = "http://github.com/o-sam-o/yayimdbs"
  s.rdoc_options = ["--main", "README.md"]
  s.rubygems_version = "2.4.8"
  s.summary = "Yet Another Ying IMDB Scraper"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency "nokogiri", "~> 1.4", ">= 1.4.2"
      s.add_runtime_dependency "activesupport", "~> 3.0", ">= 3.0.10"
      s.add_runtime_dependency "i18n", ">= 0.6.0", "< 0.7" # 0.7 requires Ruby 1.9.3
      s.add_development_dependency "rspec", "~> 2.7", ">= 2.7.0"
      s.add_development_dependency 'pry', "~> 0.10.3", ">= 0.10.3"
    else
      s.add_runtime_dependency "nokogiri", "~> 1.4", ">= 1.4.2"
      s.add_runtime_dependency "activesupport", "~> 3.0", ">= 3.0.10"
      s.add_runtime_dependency "i18n", ">= 0.6.0", "< 0.7" # 0.7 requires Ruby 1.9.3
      s.add_development_dependency "rspec", "~> 2.7", ">= 2.7.0"
      s.add_development_dependency 'pry', "~> 0.10.3", ">= 0.10.3"
    end
  else
    s.add_runtime_dependency "nokogiri", "~> 1.4", ">= 1.4.2"
    s.add_runtime_dependency "activesupport", "~> 3.0", ">= 3.0.10"
    s.add_runtime_dependency "i18n", ">= 0.6.0", "< 0.7" # 0.7 requires Ruby 1.9.3
    s.add_development_dependency "rspec", "~> 2.7", ">= 2.7.0"
    s.add_development_dependency 'pry', "~> 0.10.3", ">= 0.10.3"
  end
end
