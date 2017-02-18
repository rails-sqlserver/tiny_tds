# encoding: UTF-8
require 'date'
require 'bigdecimal'
require 'rational'

require 'tiny_tds/version'
require 'tiny_tds/error'
require 'tiny_tds/client'
require 'tiny_tds/result'
require 'tiny_tds/gem'

# Support multiple ruby versions, fat binaries under Windows.
if RUBY_PLATFORM =~ /mingw|mswin/ && RUBY_VERSION =~ /(\d+.\d+)/
  ver = Regexp.last_match(1)
  # Set the PATH environment variable, so that the DLLs can be found.
  old_path = ENV['PATH']
  begin
    ENV['PATH'] = [
      TinyTds::Gem.ports_bin_paths,
      TinyTds::Gem.ports_lib_paths,
      old_path
    ].flatten.join File::PATH_SEPARATOR

    require "tiny_tds/#{ver}/tiny_tds"
  rescue LoadError
    require 'tiny_tds/tiny_tds'
  ensure
    ENV['PATH'] = old_path
  end
else
  # Load dependent shared libraries into the process, so that they are already present,
  # when tiny_tds.so is loaded. This ensures, that shared libraries are loaded even when
  # the path is different between build and run time (e.g. Heroku).
  ports_libs = File.join(TinyTds::Gem.ports_root_path,
                         "#{RbConfig::CONFIG['host']}/lib/*.so")
  Dir[ports_libs].each do |lib|
    require 'fiddle'
    Fiddle.dlopen(lib)
  end

  require 'tiny_tds/tiny_tds'
end
