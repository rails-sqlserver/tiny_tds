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
  if ENV['TEST_FILES']
    ENV['TEST_FILES'].split(',').map{ |f| f.strip }.sort
  else
    Dir.glob("test/**/*_test.rb").sort
  end
end

def add_file_to_gem(spec, relative_path)
  target_path = File.join gem_build_path(spec), relative_path
  target_dir = File.dirname(target_path)
  mkdir_p target_dir
  rm_f target_path
  safe_ln relative_path, target_path
  spec.files += [relative_path]
end

def gem_build_path(spec)
  File.join 'pkg', spec.full_name
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

task :compile

task :build => [:clean, :compile]

task :default => [:build, :test]

Dir["tasks/*.rake"].sort.each { |f| load f }

Rake::ExtensionTask.new('tiny_tds', gemspec) do |ext|
  ext.lib_dir = 'lib/tiny_tds'
  ext.cross_compile = true
  ext.cross_platform = ['x86-mingw32', 'x64-mingw32']
  ext.cross_config_options += %w[ --disable-lookup --enable-cross-build ]

  # Add dependent DLLs to the cross gems
  ext.cross_compiling do |spec|
    platform_host_map =  {
      'x86-mingw32' => 'i686-w64-mingw32',
      'x64-mingw32' => 'x86_64-w64-mingw32'
    }

    gemplat = spec.platform.to_s
    host = platform_host_map[gemplat]

    dlls = [
      "libeay32-1.0.2d-#{host}.dll",
      "ssleay32-1.0.2d-#{host}.dll",
      "libiconv-2.dll",
      "libsybdb-5.dll",
    ]

    # We don't need the sources in a fat binary gem
    spec.files = spec.files.reject{|f| f=~/^ports\/archives/ }
    spec.files += dlls.map{|dll| "ports/#{host}/bin/#{File.basename(dll)}" }

    dlls.each do |dll|
      file "ports/#{host}/bin/#{dll}" do |t|
        sh "x86_64-w64-mingw32-strip", t.name
      end
    end
  end

end

# Bundle the freetds sources to avoid download while gem install
task gem_build_path(gemspec) do
  add_file_to_gem(gemspec, "ports/archives/freetds-0.91.112.tar.gz")
end

desc "Build the windows binary gems per rake-compiler-dock"
task 'gem:windows' do
  require 'rake_compiler_dock'
  RakeCompilerDock.sh <<-EOT
#    bundle install &&
    rake cross native gem RUBY_CC_VERSION=1.9.3:2.0.0:2.1.6:2.2.2
  EOT
end
