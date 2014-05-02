require 'mini_portile'

# If your using 0.82, you may have to make a conf file to get it to work. For example:
# $ export FREETDSCONF='/opt/local/etc/freetds/freetds.conf'
ICONV_VERSION = "1.14"
FREETDS_VERSION = ENV['TINYTDS_FREETDS_VERSION'] || "0.91"
FREETDS_VERSION_INFO = Hash.new { |h,k|
  h[k] = {:files => "ftp://ftp.astron.com/pub/freetds/stable/freetds-#{k}.tar.gz"}
}.merge({
  "0.82" => {:files => "ftp://ftp.astron.com/pub/freetds/old/0.82/freetds-0.82.tar.gz"},
  "0.91" => {:files => "ftp://ftp.astron.com/pub/freetds/stable/freetds-0.91.tar.gz"},
  "current" => {:files => "ftp://ftp.astron.com/pub/freetds/current/freetds-current.tgz"}
})

# all ports depends on this directory to exist
directory "ports"

def define_libiconv_recipe(platform, host)
  recipe = MiniPortile.new "libiconv", ICONV_VERSION
  recipe.files << "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-#{ICONV_VERSION}.tar.gz"
  recipe.host = host

  desc "Compile libiconv for '#{platform}' (#{host})"
  task "ports:libiconv:#{platform}" => ["ports"] do
    checkpoint = "ports/.#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"

    unless File.exist?(checkpoint)
      # always produce position independent code
      recipe.configure_options << "CFLAGS='-fPIC'"
      recipe.cook
      touch checkpoint
    end
  end

  recipe
end

def define_freetds_recipe(platform, host, libiconv)
  recipe = MiniPortile.new "freetds", FREETDS_VERSION
  recipe.files << FREETDS_VERSION_INFO[FREETDS_VERSION][:files]
  recipe.host = host

  if recipe.respond_to?(:patch_files) && FREETDS_VERSION == "0.91"
    recipe.patch_files << File.expand_path(File.join('..', '..', 'ext', 'patch', 'sspi_w_kerberos.diff'), __FILE__)
    recipe.patch_files << File.expand_path(File.join('..', '..', 'ext', 'patch', 'dblib-30-char-username.diff'), __FILE__)
    unless RUBY_PLATFORM =~ /mswin|mingw/
      recipe.patch_files << File.expand_path(File.join('..', '..', 'ext', 'patch', 'Makefile.in.diff'), __FILE__)
    end
  end

  desc "Compile freetds for '#{platform}' (#{host})"
  task "ports:freetds:#{platform}" => ["ports", "ports:libiconv:#{platform}"] do
    checkpoint = "ports/.#{recipe.name}-#{recipe.version}-#{recipe.host}.installed"

    unless File.exist?(checkpoint)
      with_tdsver = ENV['TINYTDS_FREETDS_VERSION'] =~ /0\.8/ ? "--with-tdsver=8.0" : "--with-tdsver=7.1"
      for_windows = recipe.host =~ /mswin|mingw/i
      recipe.configure_options << '--with-pic'
      recipe.configure_options << "--with-libiconv-prefix=#{libiconv.path}"
      recipe.configure_options << '--sysconfdir="C:/Sites"' if for_windows
      recipe.configure_options << '--enable-sspi' if for_windows
      recipe.configure_options << "--disable-odbc"
      recipe.configure_options << with_tdsver
      recipe.cook
      touch checkpoint
    end
  end

  recipe
end

# native compilation of ports
host = RbConfig::CONFIG["host"]
libiconv = define_libiconv_recipe(RUBY_PLATFORM, host)
freetds  = define_freetds_recipe(RUBY_PLATFORM, host, libiconv)

# compile native FreeTDS
desc "Compile native freetds"
task "ports:freetds" => ["ports:freetds:#{RUBY_PLATFORM}"]
