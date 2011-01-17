Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.name = 'tiny_tds'
  s.summary = 'TinyTds - A modern, simple and fast FreeTDS library for Ruby using DB-Library.'
  s.description = 'TinyTds - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter.'
  s.homepage = 'http://github.com/rails-sqlserver/tiny_tds'
  s.rdoc_options = ['--charset=UTF-8']
  s.version = '0.3.2'
  s.authors = ['Ken Collins', 'Erik Bryn']
  s.email = 'ken@metaskills.net'
  s.extensions = ['ext/tiny_tds/extconf.rb']
  s.files = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'ext/**/*', 'lib/**/*']
end
