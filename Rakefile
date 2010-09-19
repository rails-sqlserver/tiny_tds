require 'rake'
require 'rake/extensiontask'


def test_libs
  ['lib','test']
end

def test_files
  Dir.glob("test/**/*.rb").sort
end


Rake::TestTask.new(profile_case) do |t|
  t.libs = test_libs
  t.test_files = test_files
  t.verbose = true
end

Rake::ExtensionTask.new('tiny_tds') do |extension|
  extension.lib_dir = 'lib/tiny_tds'
end

task :build => [:clean, :compile]

task :default => :test


