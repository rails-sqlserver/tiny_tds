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

System Information
------------------
    Operating System:    Mac OS X 10.6.4 (10F569)
    CPU:                 Intel Core 2 Duo 2.4 GHz
    Processor Count:     2
    Memory:              4 GB
    ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-darwin10.4.0]

"Nothing" is up to 89% faster over 1,000 repetitions
----------------------------------------------------

    Nothing     0.357741832733154 secs    Fastest
    Guids       0.460683107376099 secs    22% Slower
    Bits        0.483309984207153 secs    25% Slower
    Floats      0.505340099334717 secs    29% Slower
    Moneys      0.523844003677368 secs    31% Slower
    Integers    0.616975069046021 secs    42% Slower
    Binaries    0.639773845672607 secs    44% Slower
    Decimals    0.670897960662842 secs    46% Slower
    Chars       0.800287008285522 secs    55% Slower
    Dates       0.950634956359863 secs    62% Slower
    All         2.91044211387634  secs    87% Slower

=end

