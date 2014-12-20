# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tiny_tds/version"

Gem::Specification.new do |s|
  s.name          = 'tiny_tds'
  s.version       = TinyTds::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Ken Collins', 'Erik Bryn', 'Will Bond']
  s.email         = ['ken@metaskills.net', 'will@wbond.net']
  s.homepage      = 'http://github.com/rails-sqlserver/tiny_tds'
  s.summary       = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library.'
  s.description   = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter.'
  s.files         = `git ls-files`.split("\n") - ["tiny_tds.gemspec"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.rdoc_options  = ['--charset=UTF-8']
  s.extensions    = ['ext/tiny_tds/extconf.rb']
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mini_portile'
  s.add_development_dependency 'rake-compiler'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'connection_pool'
end
