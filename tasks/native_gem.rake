CrossLibraries.each do |xlib|
	platform = xlib.platform
	
    desc "Build fat binary gem for platform #{platform}"
	task "gem:native:#{platform}" do
        require "rake_compiler_dock"

		RakeCompilerDock.sh <<-EOT, platform: platform
			bundle install &&
			rake native:#{platform} pkg/#{SPEC.full_name}-#{platform}.gem MAKEOPTS=-j`nproc` RUBY_CC_VERSION=3.4.1:3.3.5:3.2.0:3.1.0:3.0.0:2.7.0
		EOT
	end

    desc "Build the native binary gems"
	multitask 'gem:native' => "gem:native:#{platform}"
end
