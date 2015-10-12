# -*- encoding: utf-8 -*-
# stub: iso_country_codes 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "iso_country_codes"
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Alex Rabarts"]
  s.date = "2015-05-21"
  s.description = "ISO country code and currency library"
  s.email = "alexrabarts@gmail.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.homepage = "http://github.com/alexrabarts/iso_country_codes"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--charset=UTF-8"]
  s.rubygems_version = "2.4.5"
  s.summary = "Provides ISO 3166-1 country codes/names and ISO 4217 currencies."

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 0"])
      s.add_development_dependency(%q<shoulda>, ["~> 0"])
      s.add_development_dependency(%q<mocha>, ["~> 0"])
      s.add_development_dependency(%q<nokogiri>, ["~> 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 0"])
      s.add_dependency(%q<shoulda>, ["~> 0"])
      s.add_dependency(%q<mocha>, ["~> 0"])
      s.add_dependency(%q<nokogiri>, ["~> 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 0"])
    s.add_dependency(%q<shoulda>, ["~> 0"])
    s.add_dependency(%q<mocha>, ["~> 0"])
    s.add_dependency(%q<nokogiri>, ["~> 0"])
  end
end
