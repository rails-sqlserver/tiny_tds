# encoding: UTF-8

desc 'Build the windows binary gems per rake-compiler-dock'
task 'gem:windows' => ['ports:cross'] do
  require 'rake_compiler_dock'

  # make sure to install our bundle
  sh "bundle package --all"   # Avoid repeated downloads of gems by using gem files from the host.

  # and finally build the native gem
  GEM_PLATFORM_HOSTS.keys.each do |plat|
    RakeCompilerDock.sh "bundle --local && RUBY_CC_VERSION='2.7.0:2.6.0:2.5.0:2.4.0' CFLAGS='-Wall' MAKE='make -j`nproc`' rake native:#{plat} gem", platform: plat
  end
end
