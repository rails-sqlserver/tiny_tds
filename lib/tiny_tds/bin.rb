require_relative './version'

module TinyTds
  class Bin

    ROOT  = File.expand_path '../..', __FILE__
    PATHS = ENV['PATH'].split File::PATH_SEPARATOR
    EXTS  = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

    attr_reader :name

    def initialize(name, options = {})
      @name = name
      @binstub = File.join ROOT, 'bin', @name
      @exefile = File.join ROOT, 'exe', @name
      puts info unless options[:silent]
    end

    def path
      return @path if defined?(@path)
      @path = File.exists?(@exefile) ? @exefile : which
    end

    def info
      "[TinyTds][v#{TinyTds::VERSION}][#{name}]: #{path}"
    end


    private

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
