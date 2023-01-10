desc 'Cross-compiles the gem'
task 'compile:cross' do
  require 'rake_compiler_dock'

  # make sure to install our bundle
  sh "bundle package --all" # Avoid repeated downloads of gems by using gem files from the host.

  # and finally build the native gem
  GEM_PLATFORM_HOSTS.each do |gem_platform, host|
    commands = [
      "bundle --local",
      "rake ports:compile[#{host}] MAKE='make -j`nproc`'",
      "RUBY_CC_VERSION=#{RUBY_CC_VERSION} CFLAGS='-Wall' MAKE='make -j`nproc`' rake compile:#{gem_platform}"
    ]

    RakeCompilerDock.sh commands.join(" && "), platform: gem_platform
  end
end
