ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'
require 'fileutils'

# The gem version constraint in the gemspec is not respected at install time.
# Keep this version in sync with the one in the gemspec !
gem 'mini_portile2', '~> 2.0'
require 'mini_portile2'
require_relative './extconsts'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Shamelessly copied from nokogiri
#

def do_help
  print <<HELP
usage: ruby #{$0} [options]

    --enable-system-freetds / --disable-system-freetds
    --enable-system-iconv   / --disable-system-iconv
    --enable-system-openssl / --disable-system-openssl
      Force use of system or builtin freetds/iconv/openssl library.
      Default is to prefer system libraries and fallback to builtin.

    --with-freetds-dir=DIR
      Use the freetds library placed under DIR.

    --enable-lookup
      Search for freetds through all paths in the PATH environment variable.

    --disable-openssl
      Disable OpenSSL for freetds build. No effect on system-freetds.

    --enable-gnutls
      Use GnuTLS instead of OpenSSL for freetds build.

    --enable-cross-build
      Do cross-build.
HELP
  exit! 0
end

do_help if arg_config('--help')

FREETDSDIR = ENV['FREETDS_DIR']

if FREETDSDIR.nil? || FREETDSDIR.empty?
  LIBDIR     = RbConfig::CONFIG['libdir']
  INCLUDEDIR = RbConfig::CONFIG['includedir']
else
  puts "Will use #{FREETDSDIR}"
  LIBDIR = "#{FREETDSDIR}/lib"
  INCLUDEDIR = "#{FREETDSDIR}/include"
end

$CFLAGS  << " #{ENV["CFLAGS"]}"
$LDFLAGS << " #{ENV["LDFLAGS"]}"
$LIBS    << " #{ENV["LIBS"]}"

SEARCHABLE_PATHS = begin
  eop_regexp = /#{File::SEPARATOR}bin$/
  paths = ENV['PATH']
  paths = paths.gsub(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
  paths = paths.split(File::PATH_SEPARATOR)
  bin_paths = paths.select{ |p| p =~ eop_regexp }
  bin_paths.map{ |p| p.sub(eop_regexp,'') }.compact.reject{ |p| p.empty? }.uniq
end

def searchable_paths_with_directories(*directories)
  SEARCHABLE_PATHS.map do |path|
    directories.map do |paths|
      dir = File.join path, *paths
      File.directory?(dir) ? dir : nil
    end.flatten.compact
  end.flatten.compact
end

class BuildRecipe < MiniPortile
  def initialize(name, version, files)
    super(name, version)
    self.files = files
    self.target = File.expand_path('../../../ports', __FILE__)
    self.host = consolidated_host(RbConfig::CONFIG["host"])
    self.patch_files = Dir[File.join(self.target, "patches", self.name, self.version, "*.diff")].sort
  end

  def consolidated_host(name)
     # Host name and prefix of build tools are different on Windows 32 bit.
    name.gsub('i686-pc-mingw32', 'i686-w64-mingw32')
  end

  def configure_defaults
    [
      "--host=#{host}",    # build for specific target (host)
      "--disable-static",
      "--enable-shared",
    ]
  end

  # Use the same path for all recipes, so that only one include/lib path is required.
  def port_path
    "#{target}/#{host}"
  end

  # We use the same port_path for all recipes. That breaks the standard installed? method.
  def installed?
    false
  end

  # When using rake-compiler-dock on Windows, the underlying Virtualbox shared
  # folders don't support symlinks, but libiconv expects it for a build on
  # Linux. We work around this limitation by using the temp dir for cooking.
  def chdir_for_build
    build_dir = ENV['RCD_HOST_RUBY_PLATFORM'].to_s =~ /mingw|mswin|cygwin/ ? '/tmp' : '.'
    Dir.chdir(build_dir) do
      yield
    end
  end

  def cook_and_activate
    checkpoint = File.join(self.target, "#{self.name}-#{self.version}-#{self.host}.installed")
    unless File.exist?(checkpoint)
      chdir_for_build do
        self.cook
      end
      FileUtils.touch checkpoint
    end
    self.activate
    self
  end
end

def define_libssl_recipe(host)
  BuildRecipe.new("openssl", OPENSSL_VERSION, [OPENSSL_SOURCE_URI]).tap do |recipe|
    class << recipe
      def extract_file(file, target)
        filename = File.basename(file)
        FileUtils.mkdir_p target

        message "Extracting #{filename} into #{target}... "
        result = `#{tar_exe} #{tar_compression_switch(filename)}xf "#{file}" -C "#{target}" 2>&1`
        if $?.success?
          output "OK"
        else
          # tar on windows returns error exit code, because it can not extract symlinks
          output "ERROR (ignored)"
        end
      end

      def configure
        config = if host=~/mingw/
          host=~/x86_64/ ? 'mingw64' : 'mingw'
        end
        args = [ "CFLAGS=-DDSO_WIN32",
            "./Configure",
            "no-shared",
            configure_prefix,
            config,
          ]
        args.unshift("CROSS_COMPILE=#{host}-") if enable_config("cross-build")

        execute "configure", "sh -c \"#{args.join(" ")}\""
      end

      def dllwrap(dllname, outputlib, deffile, linkto)
        gcc = consolidated_host(RbConfig::CONFIG["CC"])

        #RbConfig does not provide dlltool, but it should exist where dllwrap lives
        dlltool = consolidated_host(RbConfig::CONFIG["DLLWRAP"]).sub('dllwrap','dlltool')

        execute "gcc-#{dllname}-compile", "#{gcc} -Wl,--base-file,#{dllname}.base -mdll -o #{dllname}.dll --leading-underscore #{linkto}"
        execute "dlltool-#{dllname}-exp", "#{dlltool} --base-file #{dllname}.base --output-exp #{dllname}.exp --dllname #{dllname}.dll --def #{deffile}"
        execute "gcc-#{dllname}-dll", "#{gcc} -Wl,--base-file,#{dllname}.base #{dllname}.exp -mdll -o #{dllname}.dll --leading-underscore #{linkto}"
        execute "dlltool-#{dllname}-outputlib", "#{dlltool} --base-file #{dllname}.base --output-exp #{dllname}.exp --dllname #{dllname}.dll --def #{deffile} --output-lib #{outputlib}"
        execute "gcc-#{dllname}-link", "#{gcc} #{dllname}.exp -mdll -o #{dllname}.dll --leading-underscore #{linkto}"
      end

      def compile
        super
        # OpenSSL DLLs are called "libeay32.dll" and "ssleay32.dll" per default,
        # regardless to the version. This is best suited to meet the Windows DLL hell.
        # To avoid any conflicts we do a static build and build DLLs afterwards,
        # with our own naming scheme.
        execute "mkdef-libeay32", "(perl util/mkdef.pl 32 libeay >libeay32.def)"
        execute "mkdef-ssleay32", "(perl util/mkdef.pl 32 ssleay >ssleay32.def)"
        dllwrap("libeay32-#{version}-#{host}", "libcrypto.dll.a", "libeay32.def", "libcrypto.a -lws2_32 -lgdi32 -lcrypt32")
        dllwrap("ssleay32-#{version}-#{host}", "libssl.dll.a", "ssleay32.def", "libssl.a libcrypto.dll.a")
      end

      def install
        super
        FileUtils.cp "#{work_path}/libeay32-#{version}-#{host}.dll", "#{path}/bin/"
        FileUtils.cp "#{work_path}/ssleay32-#{version}-#{host}.dll", "#{path}/bin/"
        FileUtils.cp "#{work_path}/libcrypto.dll.a", "#{path}/lib/"
        FileUtils.cp "#{work_path}/libssl.dll.a", "#{path}/lib/"
      end
    end
  end
end

def define_libiconv_recipe(host)
  BuildRecipe.new("libiconv", ICONV_VERSION, [ICONV_SOURCE_URI]).tap do |recipe|
    # always produce position independent code
    # and set an explicit optimization to avoid inline functions being optimized
    # out of libiconv
    recipe.configure_options << "CFLAGS=-fPIC -O2"
  end
end

def define_freetds_recipe(host, libiconv, libssl, gnutls)
  BuildRecipe.new("freetds", FREETDS_VERSION, [FREETDS_SOURCE_URI]).tap do |recipe|
    with_tdsver = FREETDS_VERSION =~ /0\.91/ ? "--with-tdsver=7.1" : "--with-tdsver=7.3"
    for_windows = recipe.host =~ /mswin|mingw/i
    recipe.configure_options << '--with-pic'
    recipe.configure_options << "--with-libiconv-prefix=#{libiconv.path}" if libiconv
    if true == libssl
      recipe.configure_options << "--with-openssl"
    elsif libssl
      recipe.configure_options << "--with-openssl=#{libssl.path}"
    end
    recipe.configure_options << "--with-gnutls" if gnutls
    recipe.configure_options << '--sysconfdir=C:\Sites' if for_windows
    recipe.configure_options << '--enable-sspi' if for_windows
    recipe.configure_options << "--disable-odbc"
    recipe.configure_options << with_tdsver
    if libiconv
      # For some reason freetds doesn't honor --with-libiconv-prefix
      # so we have do add it by hand:
      recipe.configure_options << "CFLAGS=-I#{libiconv.path}/include"
      recipe.configure_options << "LDFLAGS=-L#{libiconv.path}/lib -liconv"
    end

    class << recipe

      def install
        super_value = super
        # Install binstub target binaries.
        if super_value
          bin_path = File.expand_path File.join(path, 'bin')
          exe_path = File.expand_path File.join(target, '..', 'exe')
          return unless File.directory?(bin_path)
          ['tsql', 'defncopy'].each do |bin|
            ['.exe', ''].each do |ext|
              exe = File.join bin_path, "#{bin}#{ext}"
              next unless File.exists?(exe)
              next unless File.executable?(exe)
              FileUtils.cp exe, exe_path
            end
          end
        end
        super_value
      end

    end

  end
end

if RbConfig::CONFIG['target_os'] =~ /mswin32|mingw32/
  lib_prefix = 'lib' unless RbConfig::CONFIG['target_os'] =~ /mingw32/
  # There's no default include/lib dir on Windows. Let's just add the Ruby ones
  # and resort on the search path specified by INCLUDE and LIB environment
  # variables
  HEADER_DIRS = [INCLUDEDIR]
  LIB_DIRS = [LIBDIR]
else
  lib_prefix = ''
  HEADER_DIRS = [
    # First search /opt/local for macports
    '/opt/local/include',
    # Then search /usr/local for people that installed from source
    '/usr/local/include',
    # Check the ruby install locations
    INCLUDEDIR,
    # Finally fall back to /usr
    '/usr/include'
  ].reject{ |dir| !File.directory?(dir) }
  LIB_DIRS = [
    # First search /opt/local for macports
    '/opt/local/lib',
    # Then search /usr/local for people that installed from source
    '/usr/local/lib',
    # Check the ruby install locations
    LIBDIR,
    # Finally fall back to /usr
    '/usr/lib',
  ].reject{ |dir| !File.directory?(dir) }
end

FREETDS_HEADER_DIRS = (searchable_paths_with_directories(['include'],['include','freetds']) + HEADER_DIRS).uniq
FREETDS_LIB_DIRS = (searchable_paths_with_directories(['lib'],['lib','freetds']) + LIB_DIRS).uniq

# lookup over searchable paths is great for native compilation, however, when
# cross compiling we need to specify our own paths.
if enable_config("lookup", true)
  dir_config('freetds', FREETDS_HEADER_DIRS, FREETDS_LIB_DIRS)
else
  dir_config('freetds')

  # remove LDFLAGS
  $LDFLAGS = ENV.fetch("LDFLAGS", "")
end

def asplode(lib)
  msg = "-----\n"
  msg << "#{lib} is missing.\n"
  msg << "Do you have FreeTDS 0.95.80 or higher installed?\n" if lib == 'freetds'
  msg << "-----"
  abort(msg)
end

def freetds_usable?(lib_prefix)
  have_header('sybfront.h') && have_header('sybdb.h') &&
    find_library("#{lib_prefix}sybdb", 'tdsdbopen') &&
    find_library("#{lib_prefix}sybdb", 'dbanydatecrack')
end

# We use freetds, when available already, and fallback to compilation of ports
system_freetds = enable_config('system-freetds', ENV['TINYTDS_SKIP_PORTS'] || freetds_usable?(lib_prefix))

# We expect to have iconv and OpenSSL available on non-Windows systems
host = RbConfig::CONFIG["host"]
system_iconv = enable_config('system-iconv', host =~ /mingw|mswin/ ? false : true)
system_openssl = enable_config('system-openssl', host =~ /mingw|mswin/ ? false : true )
enable_gnutls = enable_config('gnutls', false )
enable_openssl = enable_config('openssl', !enable_gnutls )

unless system_freetds
  libssl = define_libssl_recipe(host).cook_and_activate unless system_openssl
  libiconv = define_libiconv_recipe(host).cook_and_activate unless system_iconv
  freetds = define_freetds_recipe(host, libiconv, libssl || enable_openssl, enable_gnutls).cook_and_activate
  dir_config('freetds', freetds.path + "/include", freetds.path + "/lib")
end

asplode 'freetds'  unless freetds_usable?(lib_prefix)

create_makefile('tiny_tds/tiny_tds')

# :startdoc:
