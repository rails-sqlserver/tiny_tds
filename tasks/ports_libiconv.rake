require File.expand_path("mini_portile", File.dirname(__FILE__))

namespace :ports do
  directory "ports"
  file "ports/.libiconv.timestamp" => ["ports"] do |f|
    recipe = MiniPortile.new("libiconv", "1.13.1", "ports")
    recipe.files = ["http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.13.1.tar.gz"]

    # download, extract, configure, compile and install, puf!
    recipe.cook

    # generate timestamp
    touch f.name
  end

  desc "Compile libiconv support library"
  task :libiconv => ["ports/.libiconv.timestamp"] do
    recipe = MiniPortile.new("libiconv", "1.13.1", "ports")
    recipe.activate
  end
end
