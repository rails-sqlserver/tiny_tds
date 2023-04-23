# encoding: UTF-8

desc 'Build the native binary gems using rake-compiler-dock'
task 'gem:native' => ['ports:cross'] do
  require 'rake_compiler_dock'

  # make sure to install our bundle
  sh "bundle package --all" # Avoid repeated downloads of gems by using gem files from the host.

  GEM_PLATFORM_HOSTS.each do |plat, meta|
    RakeCompilerDock.sh "bundle --local && RUBY_CC_VERSION=#{meta[:ruby_versions]} rake native:#{plat} gem", platform: plat
  end
end

# assumes you are in a container provided by Rake compiler
# if not, use the task above
task 'gem:for_platform', [:gem_platform] do |_task, args|
  args.with_defaults(gem_platform: RbConfig::CONFIG["arch"])

  sh "bundle install"
  Rake::Task["ports:compile"].invoke(GEM_PLATFORM_HOSTS[args.gem_platform][:host], args.gem_platform)
  sh "RUBY_CC_VERSION=#{GEM_PLATFORM_HOSTS[args.gem_platform][:ruby_versions]} rake native:#{args.gem_platform} gem"
end
