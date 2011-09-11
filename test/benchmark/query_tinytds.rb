require 'rubygems'
require 'bench_press'
$:.unshift File.expand_path('../../../lib',__FILE__)
require 'tiny_tds'

extend BenchPress

author 'Ken Collins'
summary 'Benchmark TinyTds Querys'

reps 1_000

@client = TinyTds::Client.new({ 
  :dataserver    => ENV['TINYTDS_UNIT_DATASERVER'],
  :username      => 'tinytds',
  :password      => '',
  :database      => 'tinytdstest',
  :appname       => 'TinyTds Dev',
  :login_timeout => 5,
  :timeout       => 5
})

@query_nothing  = "SELECT NULL AS [null]"
@query_ints     = "SELECT [int], [bigint], [smallint], [tinyint] FROM [datatypes]"
@query_binaries = "SELECT [binary_50], [image], [varbinary_50] FROM [datatypes]"
@query_bits     = "SELECT [bit] FROM [datatypes]"
@query_chars    = "SELECT [char_10], [nchar_10], [ntext], [nvarchar_50], [text], [varchar_50] FROM [datatypes]"
@query_dates    = "SELECT [datetime], [smalldatetime] FROM [datatypes]"
@query_decimals = "SELECT [decimal_9_2], [decimal_16_4], [numeric_18_0], [numeric_36_2] FROM [datatypes]"
@query_floats   = "SELECT [float], [real] FROM [datatypes]"
@query_moneys   = "SELECT [money], [smallmoney] FROM [datatypes]"
@query_guids    = "SELECT [uniqueidentifier] FROM [datatypes]"
@query_all      = "SELECT * FROM [datatypes]"

def select_all(query)
  @client.execute(query).each
end


measure "Nothing" do
  select_all @query_nothing
end

measure "Integers" do
  select_all @query_ints
end

measure "Binaries" do
  select_all @query_binaries
end

measure "Bits" do
  select_all @query_bits
end

measure "Chars" do
  select_all @query_chars
end

measure "Dates" do
  select_all @query_dates
end

measure "Decimals" do
  select_all @query_decimals
end

measure "Floats" do
  select_all @query_floats
end

measure "Moneys" do
  select_all @query_moneys
end

measure "Guids" do
  select_all @query_guids
end

measure "All" do
  select_all @query_all
end


=begin

Query Tinytds
=============
Author: Ken Collins  
Date: September 11, 2011  
Summary: Benchmark TinyTds Querys  

System Information
------------------
    Operating System:    Mac OS X 10.7.1 (11B26)
    CPU:                 Quad-Core Intel Xeon 2.66 GHz
    Processor Count:     4
    Memory:              24 GB
    ruby 1.8.7 (2011-02-18 patchlevel 334) [i686-darwin11.1.0], MBARI 0x6770, Ruby Enterprise Edition 2011.03

----------------------------------------------------
    (before 64bit times)                    (after 64bit times)
    Nothing     0.287657022476196 secs      Nothing     0.289273977279663 secs
    Bits        0.406533002853394 secs      Bits        0.424988031387329 secs
    Guids       0.419962882995605 secs      Guids       0.427381992340088 secs
    Floats      0.452103137969971 secs      Floats      0.455377101898193 secs
    Moneys      0.481696844100952 secs      Moneys      0.485175132751465 secs
    Integers    0.496185064315796 secs      Integers    0.525003910064697 secs
    Binaries    0.538873195648193 secs      Decimals    0.541536808013916 secs
    Decimals    0.540570974349976 secs      Binaries    0.542865991592407 secs
    Dates       0.761389970779419 secs      Dates       1.51440119743347  secs
    Chars       0.793163061141968 secs      Chars       0.666505098342896 secs
    All         4.4630811214447   secs      All         5.17242312431335  secs

=end











