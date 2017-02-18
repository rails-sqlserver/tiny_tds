require_relative './recipe'

module Ports
  class Libiconv < Recipe
    def initialize(version)
      super('libiconv', version)

      set_patches
    end

    def cook
      chdir_for_build do
        super
      end
      self
    end

    private

    # When using rake-compiler-dock on Windows, the underlying Virtualbox shared
    # folders don't support symlinks, but libiconv expects it for a build on
    # Linux. We work around this limitation by using the temp dir for cooking.
    def chdir_for_build
      build_dir = ENV['RCD_HOST_RUBY_PLATFORM'].to_s =~ /mingw|mswin|cygwin/ ? '/tmp' : '.'
      Dir.chdir(build_dir) do
        yield
      end
    end

    def configure_defaults
      [
        "--host=#{@host}",
        '--disable-static',
        '--enable-shared',
        'CFLAGS=-fPIC -O2'
      ]
    end

    def set_patches
      self.patch_files.concat get_patches(name, version)
    end
  end
end
