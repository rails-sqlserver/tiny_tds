require 'rbconfig'

module TinyTds
  module Gem
    class << self
      def root_path
        File.expand_path '../../..', __FILE__
      end

      def ports_root_path
        File.join(root_path,'ports')
      end

      def ports_bin_paths
        Dir.glob(File.join(ports_root_path,ports_host,'**','bin'))
      end

      def ports_lib_paths
        Dir.glob(File.join(ports_root_path,ports_host,'**','lib'))
      end

      def ports_host
        h = RbConfig::CONFIG['host']

        # Our fat binary builds with a i686-w64-mingw32 toolchain
        # but ruby for windows x32-mingw32 reports i686-pc-mingw32
        # so correct the host here
        h.gsub('i686-pc-mingw32', 'i686-w64-mingw32')
      end
    end
  end
end
