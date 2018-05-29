# encoding: UTF-8

desc 'Build the windows binary gems per rake-compiler-dock'
task 'gem:windows' => ['ports:cross'] do
  require 'rake_compiler_dock'

  # make sure to install our bundle
  build = ['bundle']

  # and finally build the native gem
  build << 'rake cross native gem RUBY_CC_VERSION=2.5.0:2.4.0:2.3.0:2.2.2:2.1.6:2.0.0 CFLAGS="-Wall" MAKE="make -j`nproc`"'

  RakeCompilerDock.sh build.join(' && ')
end
