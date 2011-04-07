require "mini_portile"
require "rake/extensioncompiler"

namespace :ports do

  ICONV_VERSION = "1.13.1"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_STABLE'] ? "0.82" : "0.83.dev"
  FREETDS_VERSION_INFO = {
    "0.82" => "stable",
    "0.83.dev" => "current"
  }
  FREETDS_STABLE_OR_CURRENT = FREETDS_VERSION_INFO[FREETDS_VERSION]
  ORIGINAL_HOST = RbConfig::CONFIG["arch"]

  directory "ports"

  $recipes = {}
  $recipes[:libiconv] = MiniPortile.new "libiconv", ICONV_VERSION
  $recipes[:libiconv].files << "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

  $recipes[:freetds] = MiniPortile.new "freetds", FREETDS_VERSION
  $recipes[:freetds].files << "http://ibiblio.org/pub/Linux/ALPHA/freetds/#{FREETDS_STABLE_OR_CURRENT}/freetds-#{FREETDS_STABLE_OR_CURRENT}.tgz"

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

      # HACK: Only do this when cross compiling
      # (util MiniPortile#activate gets the job done)
      unless recipe.host == ORIGINAL_HOST
        recipe.configure_options << "--with-libiconv-prefix=#{$recipes[:libiconv].path}"
      end

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
end
