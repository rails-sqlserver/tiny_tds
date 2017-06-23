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

  add_dll_path = proc do |path, &block|
    begin
      require 'ruby_installer/runtime'
      RubyInstaller::Runtime.add_dll_directory(path, &block)
    rescue LoadError
      old_path = ENV['PATH']
      ENV['PATH'] = "#{path};#{old_path}"
      begin
        block.call
      ensure
        ENV['PATH'] = old_path
      end
    end
  end

  add_dll_paths = proc do |paths, &block|
    if path=paths.shift
      add_dll_path.call(path) do
        add_dll_paths.call(paths, &block)
      end
    else
      block.call
    end
  end

  # Temporary add bin directories for DLL search, so that freetds DLLs can be found.
  add_dll_paths.call( TinyTds::Gem.ports_bin_paths ) do
    begin
      require "tiny_tds/#{ver}/tiny_tds"
    rescue LoadError
      require 'tiny_tds/tiny_tds'
    end
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
