# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'tiny_tds/version'

Gem::Specification.new do |s|
  s.name          = 'tiny_tds'
  s.version       = TinyTds::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Ken Collins', 'Erik Bryn', 'Will Bond']
  s.email         = ['ken@metaskills.net', 'will@wbond.net']
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
  s.required_ruby_version = '>= 2.0.0'
  s.metadata['msys2_mingw_dependencies'] = 'freetds'
  s.add_development_dependency 'mini_portile2', '~> 2.5.0'
  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'rake-compiler', '~> 1.2'
  s.add_development_dependency 'rake-compiler-dock', '~> 1.3.0'
  s.add_development_dependency 'minitest', '~> 5.14.0'
  s.add_development_dependency 'minitest-ci', '~> 3.4.0'
  s.add_development_dependency 'connection_pool', '~> 2.2.0'
  s.add_development_dependency 'toxiproxy', '~> 2.0.0'
end
