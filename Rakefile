# encoding: UTF-8
require 'rake'
require 'rake/clean'
require 'rbconfig'
require 'rake/testtask'
require 'rake/extensiontask'
require 'rubygems/package_task'

def test_libs
  ['lib','test']
end

def test_files
  Dir.glob("test/**/*_test.rb").sort
end

gemspec = Gem::Specification::load(File.expand_path('../tiny_tds.gemspec', __FILE__))

Rake::TestTask.new do |t|
  t.libs = test_libs
  t.test_files = test_files
  t.verbose = true
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end

task :compile => ["ports:freetds"] unless ENV['TINYTDS_SKIP_PORTS']

task :build => [:clean, :compile]

task :default => [:build, :test]

Dir["tasks/*.rake"].sort.each { |f| load f }

Rake::ExtensionTask.new('tiny_tds', gemspec) do |ext|
  ext.lib_dir = 'lib/tiny_tds'
  if RUBY_PLATFORM =~ /mswin|mingw/ then
    # Define target for extension (supporting fat binaries).
    RUBY_VERSION =~ /(\d+\.\d+)/
    ext.lib_dir = "lib/tiny_tds/#{$1}"
  else
    ext.cross_compile = true
    ext.cross_platform = []
    ext.cross_config_options << "--disable-lookup"
    config_opts = {}

    platform_host_map =  {
      'x86-mingw32' => 'i586-mingw32msvc',
      'x64-mingw32' => 'x86_64-w64-mingw32'
    }

    # This section ensures we setup up rake dependencies and that libiconv
    # and freetds are compiled using the cross-compiler and then passed to
    # extconf.rb in such a way that library detection works.
    platform_host_map.each do |plat, host|
      ext.cross_platform << plat

      libiconv = define_libiconv_recipe(plat, host)
      freetds  = define_freetds_recipe(plat, host, libiconv)
      task "native:#{plat}" => ["ports:freetds:#{plat}"] unless ENV['TINYTDS_SKIP_PORTS']

      # For some reason --with-freetds-dir and --with-iconv-dir would not work.
      # It seems the default params that extconf.rb constructs include
      # --without-freetds-include, --without-freetds-lib, --without-iconv-lib
      # and --without-iconv-include. Thus we must explicitly override them.
      config_opts[plat] = " --with-freetds-include=#{freetds.path}/include"
      config_opts[plat] += " --with-freetds-lib=#{freetds.path}/lib"
      config_opts[plat] += " --with-iconv-include=#{libiconv.path}/include"
      config_opts[plat] += " --with-iconv-lib=#{libiconv.path}/lib"
    end

    ext.cross_config_options << config_opts
  end
end
