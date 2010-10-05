Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.name = 'tiny_tds'
  s.summary = 'Tiny Ruby Wrapper For FreeTDS'
  s.description = 'Tiny ruby wrapper for FreeTDS to use with the ActiveRecord SQLServerAdapter'
  s.homepage = 'http://github.com/rails-sqlserver/tiny_tds'
  s.version = '0.0.1'
  s.authors = ['Ken Collins', 'Erik Bryn']
  s.email = 'ken@metaskills.net'
  s.extensions = ['ext/tiny_tds/extconf.rb']
  s.files = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'ext/**/*', 'lib/**/*']
end
