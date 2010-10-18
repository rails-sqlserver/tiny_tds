Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib', 'ext']
  s.rubygems_version = '1.3.7'
  s.name = 'tiny_tds'
  s.summary = 'Tiny Ruby Wrapper For FreeTDS Using DB-Library'
  s.description = 'Tiny ruby wrapper for FreeTDS developed for the ActiveRecord SQLServerAdapter'
  s.homepage = 'http://github.com/rails-sqlserver/tiny_tds'
  s.rdoc_options = ['--charset=UTF-8']
  s.version = '0.1.0'
  s.authors = ['Ken Collins', 'Erik Bryn']
  s.email = 'ken@metaskills.net'
  s.extensions = ['ext/tiny_tds/extconf.rb']
  s.files = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'ext/**/*', 'lib/**/*']
end
