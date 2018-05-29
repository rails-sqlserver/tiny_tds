# encoding: UTF-8
require 'mini_portile2'
require 'fileutils'
require_relative 'ports/libiconv'
require_relative 'ports/openssl'
require_relative 'ports/freetds'
require_relative '../ext/tiny_tds/extconsts'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if defined? OpenSSL

namespace :ports do
  openssl = Ports::Openssl.new(OPENSSL_VERSION)
  libiconv = Ports::Libiconv.new(ICONV_VERSION)
  freetds = Ports::Freetds.new(FREETDS_VERSION)

  directory "ports"

  task :openssl, [:host] do |task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'])

    openssl.files = [OPENSSL_SOURCE_URI]
    openssl.host = args.host
    openssl.cook
    openssl.activate
  end

  task :libiconv, [:host] do |task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'])

    libiconv.files = [ICONV_SOURCE_URI]
    libiconv.host = args.host
    libiconv.cook
    libiconv.activate
  end

  task :freetds, [:host] do |task, args|
    args.with_defaults(host: RbConfig::CONFIG['host'])

    freetds.files = [FREETDS_SOURCE_URI]
    freetds.host = args.host

    if openssl
      # freetds doesn't have an option that will provide an rpath
      # so we do it manually
      ENV['OPENSSL_CFLAGS'] = "-Wl,-rpath -Wl,#{openssl.path}/lib"
      # Add the pkgconfig file with MSYS2'ish path, to prefer our ports build
      # over MSYS2 system OpenSSL.
      ENV['PKG_CONFIG_PATH'] = "#{openssl.path.gsub(/^(\w):/i){"/"+$1.downcase}}/lib/pkgconfig:#{ENV['PKG_CONFIG_PATH']}"
      freetds.configure_options << "--with-openssl=#{openssl.path}"
    end

    if libiconv
      freetds.configure_options << "--with-libiconv-prefix=#{libiconv.path}"
    end

    freetds.cook
    freetds.activate
  end

  task :compile, [:host] do |task,args|
    args.with_defaults(host: RbConfig::CONFIG['host'])

    puts "Compiling ports for #{args.host}..."

    ['openssl','libiconv','freetds'].each do |lib|
      Rake::Task["ports:#{lib}"].invoke(args.host)
    end
  end

  desc 'Build the ports windows binaries via rake-compiler-dock'
  task 'cross' do
    require 'rake_compiler_dock'

    # make sure to install our bundle
    build = ['bundle']

    # build the ports for all our cross compile hosts
    GEM_PLATFORM_HOSTS.each do |gem_platform, host|
      build << "rake ports:compile[#{host}] MAKE='make -j`nproc`'"
    end

    RakeCompilerDock.sh build.join(' && ')
  end
end

desc 'Build ports and activate libraries for the current architecture.'
task :ports => ['ports:compile']
