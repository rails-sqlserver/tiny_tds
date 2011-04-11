require "mini_portile"
require "rake/extensioncompiler"

namespace :ports do

  ICONV_VERSION = "1.13.1"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_082'] ? "0.82" : "0.91"
  FREETDS_VERSION_INFO = {
    "0.82" => {:files => "http://ibiblio.org/pub/Linux/ALPHA/freetds/stable/freetds-stable.tgz"},
    "0.91" => {:files => "http://www.ibiblio.org/pub/Linux/ALPHA/freetds/current/freetds-current.tgz"} }

  ORIGINAL_HOST = RbConfig::CONFIG["arch"]

  directory "ports"

  $recipes = {}
  $recipes[:libiconv] = MiniPortile.new "libiconv", ICONV_VERSION
  $recipes[:libiconv].files << "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

  $recipes[:freetds] = MiniPortile.new "freetds", FREETDS_VERSION
  $recipes[:freetds].files << FREETDS_VERSION_INFO[FREETDS_VERSION][:files]

  desc "Compile libiconv support library"
  task :libiconv => ["ports"] do
    recipe = $recipes[:libiconv]
    checkpoint = "ports/.#{recipe.name}.#{recipe.version}.#{recipe.host}.timestamp"
    unless File.exist?(checkpoint)
      recipe.cook
      touch checkpoint
    end
    recipe.activate
  end

  desc "Compile freetds library"
  task :freetds => ["ports", :libiconv] do
    recipe = $recipes[:freetds]
    checkpoint = "ports/.#{recipe.name}.#{recipe.version}.#{recipe.host}.timestamp"
    unless File.exist?(checkpoint)
      recipe.configure_options << "--disable-odbc"
      recipe.configure_options << "--with-tdsver=7.1"
      recipe.cook
      touch checkpoint
    end
    recipe.activate
  end

end

task :cross do
  host = ENV.fetch("HOST", Rake::ExtensionCompiler.mingw_host)
  $recipes.each do |_, recipe|
    recipe.host = host
  end

  # hook compile task with dependencies
  Rake::Task["compile"].prerequisites.unshift "ports:freetds"
end
