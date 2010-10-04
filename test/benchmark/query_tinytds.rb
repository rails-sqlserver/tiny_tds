require 'rubygems'
require 'bench_press'
$:.unshift File.expand_path('../../../lib',__FILE__)
require 'tiny_tds'

extend BenchPress

author 'Ken Collins'
summary 'Benchmark TinyTds Querys'

reps 10_000

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
@query_ints     = "SELECT [int], [bigint] FROM [datatypes]"
@query_decimal  = "SELECT [decimal_9_2], [decimal_16_4] FROM [datatypes]"
@query_dates    = "SELECT [datetime] FROM [datatypes]"
@query_all      = "SELECT * FROM [datatypes]"


measure "Nothing" do
  @client.execute(@query_nothing).each
end

measure "Integers" do
  @client.execute(@query_ints).each
end

measure "Decimal" do
  @client.execute(@query_decimal).each
end

measure "Dates" do
  @client.execute(@query_dates).each
end

measure "All" do
  @client.execute(@query_all).each
end


=begin

System Information
------------------
    Operating System:    Mac OS X 10.6.4 (10F569)
    CPU:                 Quad-Core Intel Xeon 2.66 GHz
    Processor Count:     4
    Memory:              8 GB
    ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-darwin10.4.0]

"Nothing" is up to 90% faster over 10,000 repetitions
-----------------------------------------------------

    Nothing     2.24084496498108 secs    Fastest
    Integers    3.32325601577759 secs    32% Slower
    Decimal     3.47629904747009 secs    35% Slower
    Dates       5.74888300895691 secs    61% Slower
    All         24.3843479156494 secs    90% Slower

=end


