$:.unshift File.expand_path('../../../lib',__FILE__)
require 'rubygems'
require 'bench_press'
require 'tiny_tds'
require 'odbc'
require 'odbc_utf8'

extend BenchPress

author 'Ken Collins'
summary 'Query everything.'

reps 1_000

@odbc = ODBC.connect ENV['TINYTDS_UNIT_DATASERVER'], 'tinytds', ''
@odbc.use_time = true

@odbc_utf8 = ODBC_UTF8.connect ENV['TINYTDS_UNIT_DATASERVER'], 'tinytds', ''
@odbc_utf8.use_time = true

@tinytds = TinyTds::Client.new(
  :dataserver    => ENV['TINYTDS_UNIT_DATASERVER'],
  :username      => 'tinytds',
  :password      => '',
  :database      => 'tinytdstest',
  :appname       => 'TinyTds Dev',
  :login_timeout => 5,
  :timeout       => 5 )

@query_all = "SELECT * FROM [datatypes]"


measure "ODBC (ascii-8bit)" do
  h = @odbc.run(@query_all)
  h.fetch_all
  h.drop
end

# measure "ODBC (utf8)" do
#   h = @odbc_utf8.run(@query_all)
#   h.fetch_all
#   h.drop
# end

measure "TinyTDS (row caching)" do
  @tinytds.execute(@query_all).each
end

measure "TinyTDS (no caching)" do
  @tinytds.execute(@query_all).each(:cache_rows => false)
end



=begin

Author: Ken Collins  
Date: January 22, 2011  
Summary: Query everything.  

System Information
------------------
    Operating System:    Mac OS X 10.6.6 (10J567)
    CPU:                 Intel Core 2 Duo 1.6 GHz
    Processor Count:     2
    Memory:              4 GB
    ruby 1.8.7 (2010-04-19 patchlevel 253) [i686-darwin10.4.3], MBARI 0x6770, Ruby Enterprise Edition 2010.02

"TinyTDS (row caching)" is up to 79% faster over 1,000 repetitions
------------------------------------------------------------------

    TinyTDS (row caching)    4.90862512588501 secs    Fastest
    TinyTDS (no caching)     4.91626906394958 secs    0% Slower
    ODBC (ascii-8bit)        23.959536075592  secs    79% Slower

=end

