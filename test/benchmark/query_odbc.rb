require 'rubygems'
require 'bench_press'
begin gem 'odbc', '0.99992' ; rescue Gem::LoadError ; end
require 'odbc'

extend BenchPress

author 'Ken Collins'
summary 'Benchmarking ODBC Querys'

reps 1_000

@client = ODBC.connect ENV['TINYTDS_UNIT_HOST'], 'tinytds', ''
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

    Nothing     0.308742046356201 secs    Fastest
    Guids       0.381639003753662 secs    19% Slower
    Bits        0.399919986724854 secs    22% Slower
    Moneys      0.40484094619751  secs    23% Slower
    Floats      0.407542943954468 secs    24% Slower
    Integers    0.471083164215088 secs    34% Slower
    Decimals    0.474860906600952 secs    34% Slower
    Dates       0.526403188705444 secs    41% Slower
    Binaries    4.09164094924927  secs    92% Slower
    Chars       6.99407815933228  secs    95% Slower
    All         29.1598439216614  secs    98% Slower

=end

