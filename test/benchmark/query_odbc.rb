require 'rubygems'
require 'bench_press'
begin gem 'odbc', '0.99992' ; rescue Gem::LoadError ; end
require 'odbc'

extend BenchPress

author 'Ken Collins'
summary 'Benchmarking ODBC Querys'

reps 1_000

@client = ODBC.connect ENV['TINYTDS_UNIT_DATASERVER'], 'tinytds', ''
@client.use_time = true

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
  h = @client.run(query)
  h.fetch_all
  h.drop
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

"Nothing" is up to 98% faster over 1,000 repetitions
----------------------------------------------------

    Nothing     0.297961950302124 secs    Fastest
    Bits        0.377611875534058 secs    21% Slower
    Guids       0.381000995635986 secs    21% Slower
    Moneys      0.405518054962158 secs    26% Slower
    Floats      0.409428119659424 secs    27% Slower
    Integers    0.448167085647583 secs    33% Slower
    Decimals    0.471596956253052 secs    36% Slower
    Dates       0.52501106262207  secs    43% Slower
    Binaries    3.66349482536316  secs    91% Slower
    Chars       6.82928085327148  secs    95% Slower
    All         28.4982612133026  secs    98% Slower

=end

