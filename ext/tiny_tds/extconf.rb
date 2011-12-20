ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

# Shamelessly copied from nokogiri
#
LIBDIR     = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

$CFLAGS  << " #{ENV["CFLAGS"]}"
$LDFLAGS << " #{ENV["LDFLAGS"]}"
$LIBS    << " #{ENV["LIBS"]}"

if Config::CONFIG['target_os'] =~ /mswin32|mingw32/
  lib_prefix = 'lib' unless Config::CONFIG['target_os'] =~ /mingw32/

  # There's no default include/lib dir on Windows. Let's just add the Ruby ones
  # and resort on the search path specified by INCLUDE and LIB environment
  # variables
  HEADER_DIRS = [INCLUDEDIR]
  LIB_DIRS = [LIBDIR]
  FREETDS_HEADER_DIRS = [File.join(INCLUDEDIR, "freetds"), INCLUDEDIR]

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
  ]

  LIB_DIRS = [
    # First search /opt/local for macports
    '/opt/local/lib',

    # Then search /usr/local for people that installed from source
    '/usr/local/lib',

    # Check the ruby install locations
    LIBDIR,

    # Finally fall back to /usr
    '/usr/lib',
  ]

  FREETDS_HEADER_DIRS = [
    '/opt/local/include/freetds',
    '/usr/local/include/freetds',
    File.join(INCLUDEDIR, 'freetds')
  ] + HEADER_DIRS
end

dir_config('iconv',   HEADER_DIRS,         LIB_DIRS)
dir_config('freetds', FREETDS_HEADER_DIRS, LIB_DIRS)

def asplode(lib)
  abort "-----\n#{lib} is missing.\n-----"
end

asplode 'libiconv' unless have_func('iconv_open', 'iconv.h') or have_library('iconv', 'iconv_open', 'iconv.h')
asplode 'freetds'  unless have_header('sybfront.h') and have_header('sybdb.h')

asplode 'freetds'  unless find_library("#{lib_prefix}sybdb", 'tdsdbopen')
asplode 'freetds'  unless find_library("#{lib_prefix}ct",    'ct_bind')

create_makefile('tiny_tds/tiny_tds')

# :startdoc:
