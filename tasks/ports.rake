require File.expand_path("mini_portile", File.dirname(__FILE__))

namespace :ports do

  ICONV_VERSION = "1.13.1"
  OPENSSL_VERSION = "1.0.0d"
  ZLIB_VERSION = "1.2.5"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_STABLE'] ? "0.82" : "0.83.dev"
  FREETDS_VERSION_INFO = {
    "0.82" => {:files => ["http://ibiblio.org/pub/Linux/ALPHA/freetds/stable/freetds-stable.tgz"]},
    "0.83.dev" => {:files => ["http://ibiblio.org/pub/Linux/ALPHA/freetds/current/freetds-current.tgz"]}
  }

  directory "ports"

  file "ports/.libiconv.#{ICONV_VERSION}.timestamp" => ["ports"] do |f|
    recipe = MiniPortile.new "libiconv", ICONV_VERSION
    recipe.files = ["http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"]
    recipe.cook
    touch f.name
  end

  desc "Compile libiconv support library"
  task :libiconv => ["ports/.libiconv.#{ICONV_VERSION}.timestamp"] do
    recipe = MiniPortile.new "libiconv", ICONV_VERSION
    recipe.activate
  end

  file "ports/.zlib.#{ZLIB_VERSION}.timestamp" => ["ports"] do |f|
    recipe = MiniPortile.new "zlib", ZLIB_VERSION
    port_path = recipe.send(:port_path)
    recipe.files = ["http://zlib.net/zlib-#{ZLIB_VERSION}.tar.gz"]
    recipe.patchfiles = ["patchfiles/zlib-Makefile.in.diff"]
    recipe.default_config_options = ["--64", "--prefix=#{recipe.prefix}"]
    recipe.cook
    touch f.name
  end

  desc "Compile zlib support library"
  task :zlib => ["ports/.zlib.#{ZLIB_VERSION}.timestamp"] do
    recipe = MiniPortile.new "zlib", ZLIB_VERSION
    recipe.activate
  end

  file "ports/.openssl.#{OPENSSL_VERSION}.timestamp" => ["ports", "ports:zlib"] do |f|
    if ENV['TINYTDS_ENABLE_OPENSSL']
      recipe = MiniPortile.new "openssl", OPENSSL_VERSION
      recipe.files = ["http://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"]
      recipe.patchfiles = ["patchfiles/openssl-Makefile.org.diff", "patchfiles/openssl-crypto-Makefile.diff"]
      recipe.reinplacements << ['Configure', 'cc:', 'gcc-4.2:']
      recipe.default_config_options = [
        # 'no-shared',
        "-L#{recipe.prefix}/lib",
        "--openssldir=#{recipe.prefix}/etc/openssl",
        "--prefix=#{recipe.prefix}" ]
      recipe.config_options = ['zlib', 'no-asm', 'no-krb5', 'shared']
      recipe.config_command = './Configure darwin64-x86_64-cc'
      recipe.force_configure = true
      recipe.cook
      touch f.name
    end
  end

  desc "Compile openssl support library"
  task :openssl => ["ports/.openssl.#{OPENSSL_VERSION}.timestamp"] do
    if ENV['TINYTDS_ENABLE_OPENSSL']
      recipe = MiniPortile.new "openssl", OPENSSL_VERSION
      recipe.activate
    end
  end

  file "ports/.freetds.#{FREETDS_VERSION}.timestamp" => ["ports", "ports:libiconv", "ports:openssl"] do |f|
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.files = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
    recipe.config_options = [
      '--disable-odbc', 
      "--with-openssl=#{MiniPortile.new("openssl",OPENSSL_VERSION).prefix}"]
    recipe.cook
    touch f.name
  end

  desc "Compile freetds library"
  task :freetds => ["ports/.freetds.#{FREETDS_VERSION}.timestamp"] do
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.activate
  end

end
