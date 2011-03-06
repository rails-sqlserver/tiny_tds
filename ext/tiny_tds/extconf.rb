require 'mkmf'

FREETDS_LIBRARIES = ['sybdb']
FREETDS_HEADERS = ['sybfront.h', 'sybdb.h']

FREETDS_LIBRARIES.unshift 'iconv' if enable_config('iconv')

dir_config('freetds')

def root_paths
  eop_regexp = /#{File::SEPARATOR}bin$/
  paths = ENV['PATH'].split(File::PATH_SEPARATOR)
  bin_paths = paths.select{ |p| p =~ eop_regexp }
  bin_paths.map{ |p| p.sub(eop_regexp,'') }.compact.reject{ |p| p.empty? }.uniq
end

def have_freetds_libraries?(*libraries)
  libraries.all? { |l| have_library(l) }
end

def find_freetds_libraries_path
  root_paths.detect do |path|
    [['lib'],['lib','freetds']].detect do |lpaths|
      dir = File.join path, *lpaths
      message = "looking for library directory #{dir} ..."
      if File.directory?(dir)
        puts "#{message} yes"
        if with_ldflags("#{$LDFLAGS} -L#{dir}".strip) { have_freetds_libraries?(*FREETDS_LIBRARIES) }
          $LDFLAGS += "#{$LDFLAGS} -L#{dir}".strip
          true
        else
          false
        end
      else
        puts "#{message} no"
        false
      end
    end
  end
end

def have_freetds_headers?(*headers)
  headers.all? { |h| have_header(h) }
end

def find_freetds_include_path
  root_paths.detect do |path|
    [['include'],['include','freetds']].detect do |ipaths|
      dir = File.join path, *ipaths
      message = "looking for include directory #{dir} ..."
      if File.directory?(dir)
        puts "#{message} yes"
        if with_cppflags("#{$CPPFLAGS} -I#{dir}".strip) { have_freetds_headers?(*FREETDS_HEADERS) }
          $CPPFLAGS += "#{$CPPFLAGS} -I#{dir}".strip
          true
        else
          false
        end
      else
        puts "#{message} no"
        false
      end
    end
  end
end

def have_freetds?
  (have_freetds_libraries?(*FREETDS_LIBRARIES) || find_freetds_libraries_path) && 
  (have_freetds_headers?(*FREETDS_HEADERS) || find_freetds_include_path)
end

unless have_freetds?
  abort "-----\nCan not find FreeTDS's db-lib or include directory.\n-----"
end

create_makefile('tiny_tds/tiny_tds')

