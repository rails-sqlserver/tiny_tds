require_relative './version'

module TinyTds
  class Bin

    ROOT  = File.expand_path '../../..', __FILE__
    PATHS = ENV['PATH'].split File::PATH_SEPARATOR
    EXTS  = (ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']) | ['.exe']

    attr_reader :name

    class << self

      def exe(name, *args)
        bin = new(name)
        puts bin.info
        Kernel.system bin.path, *args if bin.path
      end

    end

    def initialize(name)
      @name = name
      @binstub = find_bin
      @exefile = find_exe
    end

    def path
      return @path if defined?(@path)
      @path = @exefile && File.exists?(@exefile) ? @exefile : which
    end

    def info
      "[TinyTds][v#{TinyTds::VERSION}][#{name}]: #{path}"
    end


    private

    def find_bin
      File.join ROOT, 'bin', @name
    end

    def find_exe
      EXTS.each do |ext|
        f = File.join ROOT, 'exe', "#{@name}#{ext}"
        puts f.inspect
        return f if File.exists?(f)
      end
      nil
    end

    def which
      PATHS.each do |path|
        EXTS.each do |ext|
          exe = File.expand_path File.join(path, "#{name}#{ext}"), ROOT
          next if exe == @binstub
          next if !File.executable?(exe)
          next if !binary?(exe)
          return exe
        end
      end
      return nil
    end

    # Implementation directly copied from ptools.
    # https://github.com/djberg96/ptools
    # https://opensource.org/licenses/Artistic-2.0
    #
    def binary?(file)
      bytes = File.stat(file).blksize
      return false unless bytes
      bytes = 4096 if bytes > 4096
      s = (File.read(file, bytes) || "")
      s = s.encode('US-ASCII', :undef => :replace).split(//)
      ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
    end

  end
end
