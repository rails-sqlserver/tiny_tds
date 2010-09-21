require 'mkmf'

FREETDS_HEADERS = ['sqlfront.h', 'sybdb.h']

dir_config('freetds')

def root_paths
  eop_regexp = /#{File::SEPARATOR}bin$/
  paths = ENV['PATH'].split(File::PATH_SEPARATOR)
  bin_paths = paths.select{ |p| p =~ eop_regexp }
  bin_paths.map{ |p| p.sub(eop_regexp,'') }.compact.reject{ |p| p.empty? }
end

def have_freetds_headers(*headers)
  headers.all? { |h| have_header(h) }
end

def find_freetds_include_path
  root_paths.detect do |path|
    dir = File.join path, 'include', 'freetds'
    message = "looking for #{dir} directory..."
    if File.directory?(dir)
      puts "#{message} yes"
      if with_cppflags("#{$CPPFLAGS} -I#{dir}".strip) { have_freetds_headers(*FREETDS_HEADERS) }
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


if have_freetds_headers(*FREETDS_HEADERS) || find_freetds_include_path
  
else
  abort "-----\nCan not find FreeTDS include directory.\n-----"
end


create_makefile('tiny_tds/tiny_tds')

