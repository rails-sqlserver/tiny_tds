# encoding: UTF-8
require 'rake'
require "rake/clean"
require 'rbconfig'
require 'rake/testtask'
require 'rake/extensiontask'

Dir["tasks/*.rake"].sort.each { |f| load f }

def test_libs
  ['lib','test']
end

def test_files
  Dir.glob("test/**/*_test.rb").sort
end

def gemspec
  @clean_gemspec ||= eval(File.read(File.expand_path('../tiny_tds.gemspec', __FILE__)))
end

Rake::TestTask.new do |t|
  t.libs = test_libs
  t.test_files = test_files
  t.verbose = true
end

desc "Build the gem"
task :gem => [:distclean] do
  sh %{gem build tiny_tds.gemspec}
end

desc "Try to clean up everything"
task :distclean  do
  CLEAN.concat(['pkg', 'tiny_tds-*.gem', 'tmp', 'lib/tiny_tds/tiny_tds.bundle'])
  Rake::Task[:clean].invoke
end

task :compile => ["ports:freetds"] unless ENV['TINYTDS_SKIP_PORTS']

Rake::ExtensionTask.new('tiny_tds', gemspec) do |ext|
  ext.lib_dir = 'lib/tiny_tds'
  unless ENV['TINYTDS_SKIP_PORTS']
    ext.config_options << "--enable-iconv"
    # ext.config_options << "--enable-openssl" if ENV['TINYTDS_ENABLE_OPENSSL']
  end
end

task :build => [:clean, :compile]

task :default => [:build, :test]



namespace :rvm do
  
  RVM_RUBIES = ['ruby-1.8.6', 'ruby-1.8.7', 'ruby-1.9.1', 'ruby-1.9.2', 'ree-1.8.7', 'jruby-head']
  RVM_GEMSET_NAME = 'tinytds'
  
  
  task :setup do
    unless @rvm_setup
      rvm_lib_path = "#{`echo $rvm_path`.strip}/lib"
      $LOAD_PATH.unshift(rvm_lib_path) unless $LOAD_PATH.include?(rvm_lib_path)
      require 'rvm'
      require 'tmpdir'
      @rvm_setup = true
    end
  end
  
  desc "Install development gems using bundler to each rubie version."
  task :bundle => :setup do
    rvm_each_rubie { RVM.run 'bundle install' }
  end
  
  desc "Echo command to test under each rvm rubie."
  task :test => :setup do
    puts "rvm #{rvm_rubies.join(',')} rake"
  end
  
end



# RVM Helper Methods

def rvm_each_rubie
  rvm_rubies.each do |rubie|
    RVM.use(rubie)
    yield
  end
ensure
  RVM.reset_current!
end

def rvm_rubies(options={})
  RVM_RUBIES.map{ |rubie| "#{rubie}@#{RVM_GEMSET_NAME}" }
end




