require 'test_helper'

class SchemaTest < TinyTds::TestCase
  
  context 'With SQL Server schema' do
  
    setup do
      load_current_schema
      @client ||= TinyTds::Client.new(connection_options)
      @gif1px = "GIF89a\001\000\001\000\221\000\000\377\377\377\377\377\377\376\001\002\000\000\000!\371\004\004\024\000\377\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
    end
  
    context 'for shared types' do
      
      should 'cast bigint' do
        assert_equal -9223372036854775807, find_value(11,:bigint)
        assert_equal 9223372036854775806, find_value(12,:bigint)
      end
      
      should 'cast binary' do
        assert_equal @gif1px, find_value(21,:binary_50)
      end
      
      should 'cast bit' do
        assert_equal true, find_value(31,:bit)
        assert_equal false, find_value(32,:bit)
        assert_equal nil, find_value(21,:bit)
      end
      
      should 'cast char' do
        assert_equal '1234567890', find_value(41,:char_10)
      end
      
      should 'cast decimal' do
        assert_equal BigDecimal.new('12345.01'), find_value(91,:decimal_9_2)
        assert_equal BigDecimal.new('1234567.89'), find_value(92,:decimal_9_2)
        assert_equal BigDecimal.new('0.0'), find_value(93,:decimal_16_4)
        assert_equal BigDecimal.new('123456789012.3456'), find_value(94,:decimal_16_4)
      end
      
      should 'cast float' do
        assert_equal 123.00000001, find_value(101,:float)
        assert_equal 0.0, find_value(102,:float)
        assert_equal find_value(102,:float).object_id, find_value(102,:float).object_id, 'use global zero float'
      end
      
      should 'cast image' do
        assert_equal @gif1px, find_value(141,:image)
      end
      
      should 'cast int' do
        assert_equal -2147483647, find_value(151,:int)
        assert_equal 2147483646, find_value(152,:int)
      end
      
      should 'cast money' do
        assert_equal 4.20, find_value(161,:money)
        assert_equal -922337203685477.5807, find_value(162,:money)
        assert_equal 922337203685477.5806, find_value(163,:money)
      end

      should 'cast datetime' do
        # FIXME: You must compile with MSDBLIB to support dates before 1900.
        # We use DateTime for edge-case dates, but they're really slow.
        # TODO: Is there another way to make this pass without explicitly adding local time offset?
        #       I tried adding a time offset to the value in the schema SQL file, but it didn't work.
        assert_equal DateTime.parse('1753-01-01T00:00:00.000-08:00'), find_value(61,:datetime)
        assert_equal DateTime.parse('9999-12-31T23:59:59.997-08:00'), find_value(62,:datetime)
        # We use Time for normal dates since they're faster.
        assert_equal Time.parse("2010-01-01T12:34:56.123"), find_value(63,:datetime)
        # SYBCHAR
        # assert_equal DateTime.parse('0001-01-01T00:00:00.0000000Z'), find_value(71,:datetime2_7)
        # assert_equal DateTime.parse('1984-01-24T04:20:00.0000000-08:00'), find_value(72,:datetime2_7)
        # assert_equal DateTime.parse('9999-12-31T23:59:59.9999999Z'), find_value(73,:datetime2_7)
      end
      
      should 'cast nchar' do
        assert_equal '1234567890', find_value(171, :nchar_10)
        assert_equal '123456åå', find_value(172, :nchar_10)
      end
      
      should 'cast ntext' do
        assert_equal 'test ntext', find_value(181, :ntext)
        assert_equal 'test ntext åå', find_value(182, :ntext)
      end
      
      should 'cast numeric' do
        assert_equal 191, find_value(191, :numeric_18_0)
        assert_equal 123456789012345678, find_value(192, :numeric_18_0)
        assert_equal 12345678901234567890.01, find_value(193, :numeric_36_2)
        assert_equal 123.46, find_value(194, :numeric_36_2)
      end
      
      should 'cast nvarchar' do
        assert_equal 'test nvarchar_50', find_value(201, :nvarchar_50)
        assert_equal 'test nvarchar_50 åå', find_value(202, :nvarchar_50)
        assert_equal 'test nvarchar_max', find_value(211, :nvarchar_max)
        assert_equal 'test nvarchar_max åå', find_value(212, :nvarchar_max)
      end
      
      
      should 'cast smalldatetime' do
        assert_equal Time.parse('1901-01-01T15:45:00.000'), find_value(231, :smalldatetime)
        assert_equal Time.parse('2078-06-05T04:20:00.000').to_s, find_value(232, :smalldatetime).to_s
      end

      should 'cast smallint' do
        assert_equal -32767, find_value(241, :smallint)
        assert_equal 32766, find_value(242, :smallint)
      end
    end
    
    context 'for 2005 and up' do

    end
    
    context 'for 2008 and up' do
      
      should 'cast date' do
        # Date datatype comes in as SYBCHAR
        assert_equal '0001-01-01', find_value(51,:date)
        assert_equal '9999-12-31', find_value(52,:date)
      end
      
      should 'cast datetimeoffset' do
        # SYBCHAR
        # assert_equal nil, find_value(81,:datetimeoffset_2)
        # assert_equal nil, find_value(82,:datetimeoffset_2)
        # assert_equal nil, find_value(83,:datetimeoffset_2)
        # assert_equal nil, find_value(84,:datetimeoffset_7)
        # assert_equal nil, find_value(85,:datetimeoffset_7)
        # assert_equal nil, find_value(86,:datetimeoffset_7)
      end
      
    end
  
  end
  
  
  protected
  
  def load_current_schema
    @current_schema_loaded ||= begin
      loader = TinyTds::Client.new(connection_options)
      schema_file = File.expand_path File.join(File.dirname(__FILE__), 'schema', "#{current_schema}.sql")
      schema_sql = File.read(schema_file)
      loader.execute(drop_sql).each
      loader.execute(schema_sql).cancel
      loader.close
    end
  end
  
  def drop_sql
    %|IF  EXISTS (
      SELECT TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_CATALOG = 'tinytds_test' 
      AND TABLE_TYPE = 'BASE TABLE' 
      AND TABLE_NAME = 'datatypes'
    ) 
    DROP TABLE [datatypes]|
  end
  
  def find_value(id, column)
    sql = "SELECT [#{column}] FROM [datatypes] WHERE [id] = #{id}"
    @client.execute(sql).each.first[column.to_s]
  end
  
  
end





