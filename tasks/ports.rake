
namespace :ports do

  ICONV_VERSION = "1.13.1"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_082'] ? "0.82" : "0.91rc1"
  FREETDS_VERSION_INFO = {
    "0.82" => {:files => "http://ibiblio.org/pub/Linux/ALPHA/freetds/stable/freetds-stable.tgz"},
    "0.91rc1" => {:files => "http://www.ibiblio.org/pub/Linux/ALPHA/freetds/stable/release_candidates/freetds-0.91rc1.tgz"} }

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

  file "ports/.freetds.#{FREETDS_VERSION}.timestamp" => ["ports", "ports:libiconv"] do |f|
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.files << FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
    recipe.config_options = ['--disable-odbc']
    recipe.cook
    touch f.name
  end

  desc "Compile freetds library"
  task :freetds => ["ports/.freetds.#{FREETDS_VERSION}.timestamp"] do
    recipe = MiniPortile.new "freetds", FREETDS_VERSION
    recipe.activate
  end

end
