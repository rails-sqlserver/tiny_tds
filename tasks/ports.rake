# encoding: UTF-8
require 'mini_portile2'
require 'fileutils'
require_relative 'ports/libiconv'
require_relative 'ports/openssl'
require_relative 'ports/freetds'
require_relative '../ext/tiny_tds/extconsts'

namespace :ports do
  libraries_to_compile = {
    openssl: Ports::Openssl.new(OPENSSL_VERSION),
    libiconv: Ports::Libiconv.new(ICONV_VERSION),
    freetds: Ports::Freetds.new(FREETDS_VERSION)
  }

  directory "ports"
  CLEAN.include "ports/*mingw*"
  CLEAN.include "ports/*.installed"

  task :openssl, [:host, :gem_platform] do |_task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'], gem_platform: RbConfig::CONFIG["arch"])

    libraries_to_compile[:openssl].files = [OPENSSL_SOURCE_URI]
    libraries_to_compile[:openssl].host = args.host
    libraries_to_compile[:openssl].gem_platform = args.gem_platform

    libraries_to_compile[:openssl].cook
    libraries_to_compile[:openssl].activate
  end

  task :libiconv, [:host, :gem_platform] do |_task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'], gem_platform: RbConfig::CONFIG["arch"])

    libraries_to_compile[:libiconv].files = [ICONV_SOURCE_URI]
    libraries_to_compile[:libiconv].host = args.host
    libraries_to_compile[:libiconv].gem_platform = args.gem_platform
    libraries_to_compile[:libiconv].cook
    libraries_to_compile[:libiconv].activate
  end

  task :freetds, [:host, :gem_platform] do |_task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'], gem_platform: RbConfig::CONFIG["arch"])

    libraries_to_compile[:freetds].files = [FREETDS_SOURCE_URI]
    libraries_to_compile[:freetds].host = args.host
    libraries_to_compile[:freetds].gem_platform = args.gem_platform

    if libraries_to_compile[:openssl]
      # freetds doesn't have an option that will provide an rpath
      # so we do it manually
      ENV['OPENSSL_CFLAGS'] = "-Wl,-rpath -Wl,#{libraries_to_compile[:openssl].path}/lib"
      # Add the pkgconfig file with MSYS2'ish path, to prefer our ports build
      # over MSYS2 system OpenSSL.
      ENV['PKG_CONFIG_PATH'] = "#{libraries_to_compile[:openssl].path.gsub(/^(\w):/i) { "/" + $1.downcase }}/lib/pkgconfig:#{ENV['PKG_CONFIG_PATH']}"
      libraries_to_compile[:freetds].configure_options << "--with-openssl=#{libraries_to_compile[:openssl].path}"
    end

    if libraries_to_compile[:libiconv]
      libraries_to_compile[:freetds].configure_options << "--with-libiconv-prefix=#{libraries_to_compile[:libiconv].path}"
    end

    libraries_to_compile[:freetds].cook
    libraries_to_compile[:freetds].activate
  end

  task :compile, [:host, :gem_platform] do |_task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'], gem_platform: RbConfig::CONFIG["arch"])

    puts "Compiling ports for #{args.host} (Ruby platform #{args.gem_platform}) ..."

    libraries_to_compile.keys.each do |lib|
      Rake::Task["ports:#{lib}"].invoke(args.host, args.gem_platform)
    end
  end

  desc 'Build the ports windows binaries via rake-compiler-dock'
  task 'cross' do
    require 'rake_compiler_dock'

    # build the ports for all our cross compile hosts
    GEM_PLATFORM_HOSTS.each do |gem_platform, meta|
      # make sure to install our bundle
      build = ['bundle']
      build << "RUBY_CC_VERSION=#{meta[:ruby_versions]} rake ports:compile[#{meta[:host]},#{gem_platform}] MAKE='make -j`nproc`'"
      RakeCompilerDock.sh build.join(' && '), platform: gem_platform
    end
  end

  desc "Notes the actual versions for the compiled ports into a file"
  task "version_file", [:gem_platform] do |_task, args|
    args.with_defaults(gem_platform: RbConfig::CONFIG["arch"])

    ports_version = {}

    libraries_to_compile.each do |library, library_recipe|
      ports_version[library] = library_recipe.version
    end

    ports_version[:platform] = args.gem_platform

    File.open(".ports_versions", "w") do |f|
      f.write ports_version
    end
  end
end

desc 'Build ports and activate libraries for the current architecture.'
task :ports => ['ports:compile']
