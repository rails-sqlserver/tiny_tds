require 'rubygems'
require 'bench_press'
$:.unshift File.expand_path('../../../lib',__FILE__)
require 'tiny_tds'

extend BenchPress

author 'Ken Collins'
summary 'Benchmark TinyTds Querys'

reps 1_000

@client = TinyTds::Client.new({ 
  :host          => ENV['TINYTDS_UNIT_HOST'],
  :username      => 'tinytds',
  :password      => '',
  :database      => 'tinytds_test',
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

System Information
------------------
    Operating System:    Mac OS X 10.6.4 (10F569)
    CPU:                 Intel Core 2 Duo 2.4 GHz
    Processor Count:     2
    Memory:              4 GB
    ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-darwin10.4.0]

"Nothing" is up to 88% faster over 1,000 repetitions
----------------------------------------------------

    Nothing     0.331537961959839 secs    Fastest
    Bits        0.452646970748901 secs    26% Slower
    Guids       0.460901975631714 secs    28% Slower
    Floats      0.487627029418945 secs    32% Slower
    Moneys      0.539116859436035 secs    38% Slower
    Integers    0.587196826934814 secs    43% Slower
    Binaries    0.606770038604736 secs    45% Slower
    Decimals    0.620741128921509 secs    46% Slower
    Chars       0.780858039855957 secs    57% Slower
    Dates       0.834639072418213 secs    60% Slower
    All         2.9572811126709   secs    88% Slower

=end

