require File.expand_path("mini_portile", File.dirname(__FILE__))

namespace :ports do
  
  directory "ports"
  file "ports/.libiconv.timestamp" => ["ports"] do |f|
    recipe = MiniPortile.new("libiconv", "1.13.1")
    recipe.files = ["http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"]
    recipe.cook
    touch f.name
  end

  desc "Compile libiconv support library"
  task :libiconv => ["ports/.libiconv.timestamp"] do
    recipe = MiniPortile.new("libiconv", "1.13.1")
    recipe.activate
  end

  file "ports/.freetds.timestamp" => ["ports", "ports:libiconv"] do |f|
    recipe = MiniPortile.new("freetds", "0.83.dev")
    recipe.files = ["http://ibiblio.org/pub/Linux/ALPHA/freetds/current/freetds-current.tgz"]
    recipe.cook
    touch f.name
  end

  desc "Compile freetds library"
  task :freetds => ["ports/.freetds.timestamp"] do
    recipe = MiniPortile.new("freetds", "0.83.dev")
    recipe.activate
  end
  
end
