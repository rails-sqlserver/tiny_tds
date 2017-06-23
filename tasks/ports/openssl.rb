require_relative './recipe'

module Ports
  class Openssl < Recipe
    def initialize(version)
      super('openssl', version)

      set_patches
    end

    def configure
      return if configured?

      md5_file = File.join(tmp_path, 'configure.md5')
      digest   = Digest::MD5.hexdigest(computed_options.to_s)
      File.open(md5_file, "w") { |f| f.write digest }

      # Windows doesn't recognize the shebang so always explicitly use sh
      execute('configure', "sh -c \"./Configure #{computed_options.join(' ')}\"")
    end

    def install
      unless installed?
        execute('install', %Q(#{make_cmd} install_sw install_ssldirs))
      end
    end

    private

    def execute(action, command, options={})
      # OpenSSL Requires Perl >= 5.10, while the Ruby devkit uses MSYS1 with Perl 5.8.8.
      # To overcome this, prepend Git's usr/bin to the PATH.
      # It has MSYS2 with a recent version of perl.
      prev_path = ENV['PATH']
      if host =~ /mingw/ && IO.popen(["perl", "-e", "print($])"], &:read).to_f < 5.010
        git_perl = 'C:/Program Files/Git/usr/bin'
        if File.directory?(git_perl)
          ENV['PATH'] = "#{git_perl}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
          ENV['PERL'] = 'perl'
        end
      end

      super
      ENV['PATH'] = prev_path
    end

    def configure_defaults
      opts = [
        'shared',
        target_arch
      ]

      if cross_build?
        opts << "--cross-compile-prefix=#{host}-"
      end

      opts
    end

    def target_arch
      if windows?
        arch = ''
        arch = '64' if host=~ /x86_64/

        "mingw#{arch}"
      else
        arch = 'x32'
        arch = 'x86_64' if host=~ /x86_64/

        "linux-#{arch}"
      end
    end

    def set_patches
      self.patch_files.concat get_patches(name, version)
    end
  end
end
