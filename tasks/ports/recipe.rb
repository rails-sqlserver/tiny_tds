# encoding: UTF-8
require 'mini_portile2'
require 'fileutils'
require 'rbconfig'

module Ports
  class Recipe < MiniPortile
    attr_writer :gem_platform

    def cook
      checkpoint = "ports/checkpoints/#{name}-#{version}-#{gem_platform}.installed"

      unless File.exist? checkpoint
        super
        FileUtils.mkdir_p("ports/checkpoints")
        FileUtils.touch checkpoint
      end
    end

    private

    attr_reader :gem_platform

    def port_path
      "#{@target}/#{gem_platform}/#{@name}/#{@version}"
    end

    def tmp_path
      "tmp/#{gem_platform}/ports/#{@name}/#{@version}"
    end

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
