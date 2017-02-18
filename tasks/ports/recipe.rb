# encoding: UTF-8
require 'mini_portile2'
require 'fileutils'
require 'rbconfig'

module Ports
  class Recipe < MiniPortile
    def cook
      checkpoint = "ports/#{name}-#{version}-#{host}.installed"

      unless File.exist? checkpoint
        super
        FileUtils.touch checkpoint
      end
    end

    private

    def configure_defaults
      [
        "--host=#{@host}",
        '--disable-static',
        '--enable-shared'
      ]
    end

    def windows?
      host =~ /mswin|mingw32/
    end

    def system_host
      RbConfig::CONFIG['host']
    end

    def cross_build?
      host != system_host
    end

    def get_patches(libname, version)
      patches = []
  
      patch_path = File.expand_path(
        File.join('..','..','..','patches',libname,version), 
        __FILE__
      )

      patches.concat(Dir[File.join(patch_path, '*.patch')].sort)
      patches.concat(Dir[File.join(patch_path, '*.diff')].sort)
    end
  end
end

