# encoding: UTF-8
require 'rake'
require "rake/clean"
require 'rbconfig'
require 'rake/testtask'
require 'rake/extensiontask'



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
  CLEAN.concat(['pkg', 'tiny_tds-*.gem', 'tmp'])
  Rake::Task[:clean].invoke
end

Rake::ExtensionTask.new('tiny_tds', gemspec) do |ext|
  ext.lib_dir = 'lib/tiny_tds'
end

task :build => [:clean, :compile]

task :default => [:build, :test]


