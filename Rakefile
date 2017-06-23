# encoding: UTF-8
require 'rbconfig'
require 'rake'
require 'rake/clean'
require 'rake/extensiontask'
require_relative './ext/tiny_tds/extconsts'

SPEC = Gem::Specification.load(File.expand_path('../tiny_tds.gemspec', __FILE__))
GEM_PLATFORM_HOSTS = {
  'x86-mingw32' => 'i686-w64-mingw32',
  'x64-mingw32' => 'x86_64-w64-mingw32'
}

# Add our project specific files to clean for a rebuild
CLEAN.include FileList["{ext,lib}/**/*.{so,#{RbConfig::CONFIG['DLEXT']},o}"],
  FileList["exe/*"]

# Clobber all our temp files and ports files including .install files
# and archives
CLOBBER.include FileList["tmp/**/*"],
  FileList["ports/**/*"].exclude(%r{^ports/archives})

Dir['tasks/*.rake'].sort.each { |f| load f }

Rake::ExtensionTask.new('tiny_tds', SPEC) do |ext|
  ext.lib_dir = 'lib/tiny_tds'
  ext.cross_compile = true
  ext.cross_platform = GEM_PLATFORM_HOSTS.keys

  # Add dependent DLLs to the cross gems
  ext.cross_compiling do |spec|
    # The fat binary gem doesn't depend on the freetds package, since it bundles the library.
    spec.metadata.delete('msys2_mingw_dependencies')

    platform_host_map = GEM_PLATFORM_HOSTS
    gemplat = spec.platform.to_s
    host = platform_host_map[gemplat]

    # We don't need the sources in a fat binary gem
    spec.files = spec.files.reject { |f| f =~ %r{^ports\/archives/} }

    # Make sure to include the ports binaries and libraries
    spec.files += FileList["ports/#{host}/**/**/{bin,lib}/*"].exclude do |f|
      File.directory? f
    end

    spec.files += Dir.glob('exe/*')
  end
end

task build: [:clean, :compile]
task default: [:build, :test]

