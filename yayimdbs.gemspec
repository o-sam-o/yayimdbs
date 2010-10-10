# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{yayimdbs}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sam Cavenagh"]
  s.date = %q{2010-10-10}
  s.description = %q{A simple imdb scraper built on Nokogiri for ruby 1.9+}
  s.email = %q{cavenaghweb@hotmail.com}
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "spec", "lib/yay_imdbs.rb"]
  s.homepage = %q{http://github.com/o-sam-o/yayimdbs}
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Yet Another Ying IMDB Scraper}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.4.2"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<tzinfo>, [">= 0.3.22"])
      s.add_runtime_dependency(%q<i18n>, [">= 0.4.1"])
      s.add_development_dependency(%q<rspec>, [">= 1.3.1"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<tzinfo>, [">= 0.3.22"])
      s.add_dependency(%q<i18n>, [">= 0.4.1"])
      s.add_dependency(%q<rspec>, [">= 1.3.1"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.4.2"])
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<tzinfo>, [">= 0.3.22"])
    s.add_dependency(%q<i18n>, [">= 0.4.1"])
    s.add_dependency(%q<rspec>, [">= 1.3.1"])
  end
end
