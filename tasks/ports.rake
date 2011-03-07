require File.expand_path("mini_portile", File.dirname(__FILE__))

namespace :ports do

  ICONV_VERSION = "1.13.1"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_STABLE'] ? "0.82" : "0.83.dev"
  FREETDS_VERSION_INFO = {
    "0.82" => {:files => ["http://ibiblio.org/pub/Linux/ALPHA/freetds/stable/freetds-stable.tgz"]},
    "0.83.dev" => {:files => ["http://ibiblio.org/pub/Linux/ALPHA/freetds/current/freetds-current.tgz"]}
  }

  directory "ports"

  file "ports/.libiconv.timestamp" => ["ports"] do |f|
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

  file "ports/.freetds.#{FREETDS_VERSION}.timestamp" => ["ports", "ports:libiconv"] do |f|
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.files = FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
    recipe.cook
    touch f.name
  end

  desc "Compile freetds library"
  task :freetds => ["ports/.freetds.#{FREETDS_VERSION}.timestamp"] do
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.activate
  end

end
