# encoding: UTF-8
require 'rbconfig'
require 'rake'
require 'rake/clean'
require 'rake/extensiontask'
require_relative './ext/tiny_tds/extconsts'

SPEC = Gem::Specification.load(File.expand_path('../tiny_tds.gemspec', __FILE__))

ruby_cc_ucrt_versions = "3.2.0:3.1.0".freeze
ruby_cc_mingw32_versions = "3.0.0:2.7.0:2.6.0:2.5.0:2.4.0".freeze

GEM_PLATFORM_HOSTS = {
  'x86-mingw32' => {
    host: 'i686-w64-mingw32',
    ruby_versions: ruby_cc_mingw32_versions
  },
  'x64-mingw32' => {
    host: 'x86_64-w64-mingw32',
    ruby_versions: ruby_cc_mingw32_versions
  },
  'x64-mingw-ucrt' => {
    host: 'x86_64-w64-mingw32',
    ruby_versions: ruby_cc_ucrt_versions
  },
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

    # We don't need the sources in a fat binary gem
    spec.files = spec.files.reject { |f| f =~ %r{^ports\/archives/} }

    # Make sure to include the ports binaries and libraries
    spec.files += FileList["ports/#{spec.platform.to_s}/**/**/{bin,lib}/*"].exclude do |f|
      File.directory? f
    end

    spec.files += Dir.glob('exe/*')
  end
end

task build: [:clean, :compile]
task default: [:build, :test]
