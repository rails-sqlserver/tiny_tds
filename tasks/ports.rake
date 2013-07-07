require 'mini_portile'
require 'rake/extensioncompiler'

namespace :ports do
  
  # If your using 0.82, you may have to make a conf file to get it to work. For example:
  # $ export FREETDSCONF='/opt/local/etc/freetds/freetds.conf'
  ICONV_VERSION = "1.13.1"
  FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "0.91"
  FREETDS_VERSION_INFO = Hash.new { |h,k|
    h[k] = {:files => "ftp://ftp.astron.com/pub/freetds/stable/freetds-#{k}.tar.gz"}
  }.merge({
    "0.82" => {:files => "ftp://ftp.astron.com/pub/freetds/old/0.82/freetds-0.82.tar.gz"},
    "0.91" => {:files => "ftp://ftp.astron.com/pub/freetds/stable/freetds-0.91.tar.gz"},
    "current" => {:files => "ftp://ftp.astron.com/pub/freetds/current/freetds-current.tgz"}
  })

  directory "ports"

  $recipes = {}
  $recipes[:libiconv] = MiniPortile.new "libiconv", ICONV_VERSION
  $recipes[:libiconv].files << "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"

  $recipes[:freetds] = MiniPortile.new "freetds", FREETDS_VERSION
  $recipes[:freetds].files << FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
  if $recipes[:freetds].respond_to?(:patch_files)
    if FREETDS_VERSION == "0.91"
      $recipes[:freetds].patch_files << File.expand_path(File.join('..', '..', 'ext', 'patch', 'sspi_w_kerberos.diff'), __FILE__) 
    end
  end

  desc "Compile libiconv support library"
  task :libiconv => ["ports"] do
    recipe = $recipes[:libiconv]
    checkpoint = "ports/.#{recipe.name}.#{recipe.version}.#{recipe.host}.timestamp"
    unless File.exist?(checkpoint)
      recipe.configure_options << "CFLAGS='-fPIC'"
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
      with_tdsver = ENV['TINYTDS_FREETDS_VERSION'] =~ /0\.8/ ? "--with-tdsver=8.0" : "--with-tdsver=7.1"
      for_windows = recipe.host =~ /mswin|mingw/i
      recipe.configure_options << '--sysconfdir="C:/Sites"' if for_windows
      recipe.configure_options << '--enable-sspi' if for_windows
      recipe.configure_options << "--disable-odbc"
      recipe.configure_options << with_tdsver
      recipe.configure_options << "CFLAGS='-fPIC'"
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
