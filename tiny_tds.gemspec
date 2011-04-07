Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.7'
  s.name = 'tiny_tds'
  s.summary = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library.'
  s.description = 'TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter.'
  s.homepage = 'http://github.com/rails-sqlserver/tiny_tds'
  s.rdoc_options = ['--charset=UTF-8']
  s.version = '0.4.3'
  s.authors = ['Ken Collins', 'Erik Bryn']
  s.email = 'ken@metaskills.net'
  s.extensions = ['ext/tiny_tds/extconf.rb']

  # use git file manifest instead of globing, exclude the gemspec from the list of files
  s.files = `git ls-files`.split - ["tiny_tds.gemspec"]
end
