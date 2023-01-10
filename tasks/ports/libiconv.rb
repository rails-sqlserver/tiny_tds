require_relative './recipe'

module Ports
  class Libiconv < Recipe
    def initialize(version)
      super('libiconv', version)

      set_patches
    end

    private

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
