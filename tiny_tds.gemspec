# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'tiny_tds/version'

Gem::Specification.new do |s|
  s.name          = 'tiny_tds'
  s.version       = TinyTds::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Ken Collins', 'rails-sqlserver volunteers']
  s.email         = ['ken@metaskills.net']
  s.homepage      = 'http://github.com/rails-sqlserver/tiny_tds'
  s.summary       = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library.'
  s.description   = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter.'
  s.files         = `git ls-files`.split("\n") + Dir.glob('exe/*')
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.rdoc_options  = ['--charset=UTF-8']
  s.extensions    = ['ext/tiny_tds/extconf.rb']
  s.license       = 'MIT'
  s.required_ruby_version = '>= 2.7.0'
  s.metadata['msys2_mingw_dependencies'] = 'freetds'
  s.add_dependency 'bigdecimal', '~> 3'
  s.add_development_dependency 'mini_portile2', '~> 2.5.0'
  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'rake-compiler', '~> 1.2'
  s.add_development_dependency 'rake-compiler-dock', '~> 1.7.0'
  s.add_development_dependency 'minitest', '~> 5.25'
  s.add_development_dependency 'minitest-reporters', '~> 1.6.1'
  s.add_development_dependency 'connection_pool', '~> 2.2.0'
  s.add_development_dependency 'toxiproxy', '~> 2.0.0'
end
