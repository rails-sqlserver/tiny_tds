require_relative './recipe'

module Ports
  class Freetds < Recipe
    def initialize(version)
      super('freetds', version)

      set_patches
    end

    private

    def configure_defaults
      opts = super

      opts << '--with-pic'
      opts << '--disable-odbc'

      if version =~ /0\.91/
        opts << '--with-tdsver=7.1'
      else
        opts << '--with-tdsver=7.3'
      end

      if windows?
        opts << '--sysconfdir=C:/Sites'
        opts << '--enable-sspi'
      end

      opts
    end

    def set_patches
      self.patch_files.concat get_patches(name, version)
    end
  end
end
