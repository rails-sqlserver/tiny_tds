ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

# Shamelessly copied from nokogiri
#
LIBDIR     = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

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
  dir_config('iconv',   FREETDS_HEADER_DIRS, FREETDS_LIB_DIRS)
  dir_config('freetds', FREETDS_HEADER_DIRS, FREETDS_LIB_DIRS)
else
  dir_config('iconv')
  dir_config('freetds')

  # remove LDFLAGS
  $LDFLAGS = ENV.fetch("LDFLAGS", "")
end

def asplode(lib)
  abort "-----\n#{lib} is missing.\n-----"
end

asplode 'libiconv' unless have_func('iconv_open', 'iconv.h') || have_library('iconv', 'iconv_open', 'iconv.h')
asplode 'freetds'  unless have_header('sybfront.h') && have_header('sybdb.h')

asplode 'freetds'  unless find_library("#{lib_prefix}sybdb", 'tdsdbopen')
asplode 'freetds'  unless find_library("#{lib_prefix}ct",    'ct_bind')

create_makefile('tiny_tds/tiny_tds')

# :startdoc:
