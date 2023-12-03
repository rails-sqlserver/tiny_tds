ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'
require 'rbconfig'
require_relative './extconsts'

# Shamelessly copied from nokogiri
#

def do_help
  print <<HELP
usage: ruby #{$0} [options]
    --with-freetds-dir=DIR
      Use the freetds library placed under DIR.
HELP
  exit! 0
end

do_help if arg_config('--help')

# Make sure to check the ports path for the configured host
architecture = RbConfig::CONFIG['arch']
architecture = "x86-mingw32" if architecture == "i386-mingw32"

project_dir = File.expand_path("../../..", __FILE__)
freetds_ports_dir = File.join(project_dir, 'ports', architecture, 'freetds', FREETDS_VERSION)
freetds_ports_dir = File.expand_path(freetds_ports_dir)

# Add all the special path searching from the original tiny_tds build
# order is important here! First in, first searched.
DIRS = %w(
  /opt/local
  /usr/local
)

if RbConfig::CONFIG['host_os'] =~ /darwin/i
  # Ruby below 2.7 seems to label the host CPU on Apple Silicon as aarch64
  # 2.7 and above print is as ARM64
  target_host_cpu = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7') ? 'aarch64' : 'arm64'

  if RbConfig::CONFIG['host_cpu'] == target_host_cpu
    # Homebrew on Apple Silicon installs into /opt/hombrew
    # https://docs.brew.sh/Installation
    # On Intel Macs, it is /usr/local, so no changes necessary to DIRS
    DIRS.unshift("/opt/homebrew")
  end
end

if ENV["RI_DEVKIT"] && ENV["MINGW_PREFIX"] # RubyInstaller Support
  DIRS.unshift(File.join(ENV["RI_DEVKIT"], ENV["MINGW_PREFIX"]))
end

# Add the ports directory if it exists for local developer builds
DIRS.unshift(freetds_ports_dir) if File.directory?(freetds_ports_dir)

# Grab freetds environment variable for use by people on services like
# Heroku who they can't easily use bundler config to set directories
DIRS.unshift(ENV['FREETDS_DIR']) if ENV.has_key?('FREETDS_DIR')

# Add the search paths for freetds configured above
ldirs = DIRS.flat_map do |path|
  ldir = "#{path}/lib"
  [ldir, "#{ldir}/freetds"]
end

idirs = DIRS.flat_map do |path|
  idir = "#{path}/include"
  [idir, "#{idir}/freetds"]
end

puts "looking for freetds headers in the following directories:\n#{idirs.map{|a| " - #{a}\n"}.join}"
puts "looking for freetds library in the following directories:\n#{ldirs.map{|a| " - #{a}\n"}.join}"
dir_config('freetds', idirs, ldirs)

have_dependencies = [
  find_header('sybfront.h'),
  find_header('sybdb.h'),
  find_library('sybdb', 'tdsdbopen'),
  find_library('sybdb', 'dbanydatecrack')
].inject(true) do |memo, current|
  memo && current
end

unless have_dependencies
  abort 'Failed! Do you have FreeTDS 0.95.80 or higher installed?'
end

create_makefile('tiny_tds/tiny_tds')

# :startdoc:
