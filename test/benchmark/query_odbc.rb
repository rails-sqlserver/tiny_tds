require 'rubygems'
require 'bench_press'
require 'odbc'

extend BenchPress

author 'Ken Collins'
summary 'Benchmarking ODBC Querys'

reps 10_000

@client = ODBC.connect ENV['TINYTDS_UNIT_HOST'], 'tinytds', ''

@query_nothing  = "SELECT NULL AS [null]"
@query_ints     = "SELECT [int], [bigint] FROM [datatypes]"
@query_decimal  = "SELECT [decimal_9_2], [decimal_16_4] FROM [datatypes]"
@query_dates    = "SELECT [datetime] FROM [datatypes]"
@query_all      = "SELECT * FROM [datatypes]"


measure "Nothing" do
  h = @client.run(@query_nothing)
  h.fetch_all
  h.drop
end

measure "Integers" do
  h = @client.run(@query_ints)
  h.fetch_all
  h.drop
end

measure "Decimal" do
  h = @client.run(@query_decimal)
  h.fetch_all
  h.drop
end

measure "Dates" do
  h = @client.run(@query_dates)
  h.fetch_all
  h.drop
end

measure "All" do
  h = @client.run(@query_all)
  h.fetch_all
  h.drop
end


=begin

System Information
------------------
    Operating System:    Mac OS X 10.6.4 (10F569)
    CPU:                 Quad-Core Intel Xeon 2.66 GHz
    Processor Count:     4
    Memory:              8 GB
    ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-darwin10.4.0]

"Nothing" is up to 98% faster over 10,000 repetitions
-----------------------------------------------------

    Nothing     2.35704398155212 secs    Fastest
    Dates       2.87141299247742 secs    17% Slower
    Integers    3.08670210838318 secs    23% Slower
    Decimal     3.11463308334351 secs    24% Slower
    All         118.064773082733 secs    98% Slower

=end


