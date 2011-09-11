# encoding: utf-8
require 'test_helper'

class SchemaTest < TinyTds::TestCase
  
  context 'Casting SQL Server schema' do
  
    setup do
      @@current_schema_loaded ||= load_current_schema
      @client ||= new_connection
      @gif1px = ruby19? ? File.read('test/schema/1px.gif',:mode=>"rb:BINARY") : File.read('test/schema/1px.gif')
    end
  
    context 'for shared types' do
      
      should 'cast bigint' do
        assert_equal -9223372036854775807, find_value(11, :bigint)
        assert_equal 9223372036854775806, find_value(12, :bigint)
      end
      
      should 'cast binary' do
        binary_value = sqlserver_azure? ? @gif1px : @gif1px+"\000"
        value = find_value(21, :binary_50)
        assert_equal binary_value, value
        assert_binary_encoding(value)
      end
      
      should 'cast bit' do
        assert_equal true, find_value(31, :bit)
        assert_equal false, find_value(32, :bit)
        assert_equal nil, find_value(21, :bit)
      end
      
      should 'cast char' do
        partial_char = sqlserver_azure? ? '12345678' : '12345678  '
        assert_equal '1234567890', find_value(41, :char_10)
        assert_equal partial_char, find_value(42, :char_10)
        assert_utf8_encoding find_value(42, :char_10)
      end
      
      should 'cast datetime' do
        if ruby18? && 1.size == 4 #32 bit
          # 1753-01-01T00:00:00.000
          v = find_value 61, :datetime
          assert_instance_of DateTime, v, 'not in range of Time class'
          assert_equal 1753, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 0, v.hour
          assert_equal 0, v.min
          assert_equal 0, v.sec
          assert_equal 0, v.usec
          # 9999-12-31T23:59:59.997
          v = find_value 62, :datetime
          assert_instance_of DateTime, v, 'not in range of Time class'
          assert_equal 9999, v.year
          assert_equal 12, v.month
          assert_equal 31, v.day
          assert_equal 23, v.hour
          assert_equal 59, v.min
          assert_equal 59, v.sec
          assert_equal 997000, v.usec unless ruby186?
          assert_equal local_offset, find_value(62, :datetime, :timezone => :local).offset
          assert_equal 0, find_value(62, :datetime, :timezone => :utc).offset
          # 2010-01-01T12:34:56.123
          v = find_value 63, :datetime
          assert_instance_of Time, v, 'in range of Time class'
          assert_equal 2010, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 12, v.hour
          assert_equal 34, v.min
          assert_equal 56, v.sec
          assert_equal 123000, v.usec
          assert_equal utc_offset, find_value(63, :datetime, :timezone => :local).utc_offset
          assert_equal 0, find_value(63, :datetime, :timezone => :utc).utc_offset
        else
          # 1753-01-01T00:00:00.000
          v = find_value 61, :datetime
          assert_instance_of Time, v, 'not in range of Time class'
          assert_equal 1753, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 0, v.hour
          assert_equal 0, v.min
          assert_equal 0, v.sec
          assert_equal 0, v.usec
          # 9999-12-31T23:59:59.997
          v = find_value 62, :datetime
          assert_instance_of Time, v, 'not in range of Time class'
          assert_equal 9999, v.year
          assert_equal 12, v.month
          assert_equal 31, v.day
          assert_equal 23, v.hour
          assert_equal 59, v.min
          assert_equal 59, v.sec
          assert_equal 997000, v.usec unless ruby186?
          assert_equal utc_offset, find_value(62, :datetime, :timezone => :local).utc_offset
          assert_equal 0, find_value(62, :datetime, :timezone => :utc).utc_offset
          # 2010-01-01T12:34:56.123
          v = find_value 63, :datetime
          assert_instance_of Time, v, 'in range of Time class'
          assert_equal 2010, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 12, v.hour
          assert_equal 34, v.min
          assert_equal 56, v.sec
          assert_equal 123000, v.usec
          assert_equal utc_offset, find_value(63, :datetime, :timezone => :local).utc_offset
          assert_equal 0, find_value(63, :datetime, :timezone => :utc).utc_offset
        end
      end
      
      should 'cast decimal' do
        assert_instance_of BigDecimal, find_value(91, :decimal_9_2)
        assert_equal BigDecimal.new('12345.01'), find_value(91, :decimal_9_2)
        assert_equal BigDecimal.new('1234567.89'), find_value(92, :decimal_9_2)
        assert_equal BigDecimal.new('0.0'), find_value(93, :decimal_16_4)
        assert_equal BigDecimal.new('123456789012.3456'), find_value(94, :decimal_16_4)
      end
      
      should 'cast float' do
        assert_equal 123.00000001, find_value(101,:float)
        assert_equal 0.0, find_value(102,:float)
        assert_equal find_value(102,:float).object_id, find_value(102,:float).object_id, 'use global zero float'
        assert_equal 123.45, find_value(103,:float)
      end
      
      should 'cast image' do
        value = find_value(141,:image)
        assert_equal @gif1px, value
        assert_binary_encoding(value)
      end
      
      should 'cast int' do
        assert_equal -2147483647, find_value(151, :int)
        assert_equal 2147483646, find_value(152, :int)
      end
      
      should 'cast money' do
        assert_instance_of BigDecimal, find_value(161, :money)
        assert_equal BigDecimal.new('4.20'), find_value(161, :money)
        assert_equal BigDecimal.new('922337203685477.5806'), find_value(163 ,:money)
        assert_equal BigDecimal.new('-922337203685477.5807'), find_value(162 ,:money)
      end
      
      should 'cast nchar' do
        assert_equal '1234567890', find_value(171, :nchar_10)
        assert_equal '123456åå  ', find_value(172, :nchar_10)
        assert_equal 'abc123    ', find_value(173, :nchar_10)
      end
      
      should 'cast ntext' do
        assert_equal 'test ntext', find_value(181, :ntext)
        assert_equal 'test ntext åå', find_value(182, :ntext)
        assert_utf8_encoding find_value(182, :ntext)
        # If this test fails, try setting the "text size" in your freetds.conf. See: http://www.freetds.org/faq.html#textdata
        large_value = "x" * 5000
        large_value_id = @client.execute("INSERT INTO [datatypes] ([ntext]) VALUES (N'#{large_value}')").insert
        assert_equal large_value, find_value(large_value_id, :ntext)
      end
      
      should 'cast numeric' do
        assert_instance_of BigDecimal, find_value(191, :numeric_18_0)
        assert_equal BigDecimal('191'), find_value(191, :numeric_18_0)
        assert_equal BigDecimal('123456789012345678'), find_value(192, :numeric_18_0)
        assert_equal BigDecimal('12345678901234567890.01'), find_value(193, :numeric_36_2)
        assert_equal BigDecimal('123.46'), find_value(194, :numeric_36_2)
      end
      
      should 'cast nvarchar' do
        assert_equal 'test nvarchar_50', find_value(201, :nvarchar_50)
        assert_equal 'test nvarchar_50 åå', find_value(202, :nvarchar_50)
        assert_utf8_encoding find_value(202, :nvarchar_50)
      end
      
      should 'cast real' do
        assert_in_delta 123.45, find_value(221, :real), 0.01
        assert_equal 0.0, find_value(222, :real)
        assert_equal find_value(222, :real).object_id, find_value(222, :real).object_id, 'use global zero float'
        assert_in_delta 0.00001, find_value(223, :real), 0.000001
      end
      
      should 'cast smalldatetime' do
        if ruby18? && 1.size == 4 #32 bit        
          # 1901-01-01 15:45:00
          v = find_value 231, :smalldatetime
          assert_instance_of DateTime, v
          assert_equal 1901, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 15, v.hour
          assert_equal 45, v.min
          assert_equal 00, v.sec
          assert_equal local_offset, find_value(231, :smalldatetime, :timezone => :local).offset
          assert_equal 0, find_value(231, :smalldatetime, :timezone => :utc).offset
          # 2078-06-05 04:20:00
          v = find_value 232, :smalldatetime
          assert_instance_of DateTime, v
          assert_equal 2078, v.year
          assert_equal 06, v.month
          assert_equal 05, v.day
          assert_equal 04, v.hour
          assert_equal 20, v.min
          assert_equal 00, v.sec
          assert_equal local_offset, find_value(232, :smalldatetime, :timezone => :local).offset
          assert_equal 0, find_value(232, :smalldatetime, :timezone => :utc).offset
        else
          # 1901-01-01 15:45:00
          v = find_value 231, :smalldatetime
          assert_instance_of Time, v
          assert_equal 1901, v.year
          assert_equal 01, v.month
          assert_equal 01, v.day
          assert_equal 15, v.hour
          assert_equal 45, v.min
          assert_equal 00, v.sec
          assert_equal Time.local(1901).utc_offset, find_value(231, :smalldatetime, :timezone => :local).utc_offset
          assert_equal 0, find_value(231, :smalldatetime, :timezone => :utc).utc_offset
          # 2078-06-05 04:20:00
          v = find_value 232, :smalldatetime
          assert_instance_of Time, v
          assert_equal 2078, v.year
          assert_equal 06, v.month
          assert_equal 05, v.day
          assert_equal 04, v.hour
          assert_equal 20, v.min
          assert_equal 00, v.sec
          assert_equal Time.local(2078,6).utc_offset, find_value(232, :smalldatetime, :timezone => :local).utc_offset
          assert_equal 0, find_value(232, :smalldatetime, :timezone => :utc).utc_offset
        end
      end
      
      should 'cast smallint' do
        assert_equal -32767, find_value(241, :smallint)
        assert_equal 32766, find_value(242, :smallint)
      end
      
      should 'cast smallmoney' do
        assert_instance_of BigDecimal, find_value(251, :smallmoney)
        assert_equal BigDecimal.new("4.20"), find_value(251, :smallmoney)
        assert_equal BigDecimal.new("-214748.3647"), find_value(252, :smallmoney)
        assert_equal BigDecimal.new("214748.3646"), find_value(253, :smallmoney)
      end
      
      should 'cast text' do
        assert_equal 'test text', find_value(271, :text)
        assert_utf8_encoding find_value(271, :text)
      end
      
      should 'cast tinyint' do
        assert_equal 0, find_value(301, :tinyint)
        assert_equal 255, find_value(302, :tinyint)
      end
      
      should 'cast uniqueidentifier' do
        assert_match %r|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|, find_value(311, :uniqueidentifier)
        assert_utf8_encoding find_value(311, :uniqueidentifier)
      end
      
      should 'cast varbinary' do
        value = find_value(321, :varbinary_50)
        assert_equal @gif1px, value
        assert_binary_encoding(value)
      end
      
      should 'cast varchar' do
        assert_equal 'test varchar_50', find_value(341, :varchar_50)
        assert_utf8_encoding find_value(341, :varchar_50)
      end
      
    end
    
    
    context 'for 2005 and up' do
      
      should 'cast nvarchar(max)' do
        assert_equal 'test nvarchar_max', find_value(211, :nvarchar_max)
        assert_equal 'test nvarchar_max åå', find_value(212, :nvarchar_max)
        assert_utf8_encoding find_value(212, :nvarchar_max)
      end
      
      should 'cast varbinary(max)' do
        value = find_value(331, :varbinary_max)
        assert_equal @gif1px, value
        assert_binary_encoding(value)
      end
      
      should 'cast varchar(max)' do
        value = find_value(351, :varchar_max)
        assert_equal 'test varchar_max', value
        assert_utf8_encoding(value)
      end
      
      should 'cast xml' do
        value = find_value(361, :xml)
        assert_equal '<foo><bar>batz</bar></foo>', value
        assert_utf8_encoding(value)
      end
      
    end if sqlserver_2005? || sqlserver_2008? || sqlserver_azure?
    
    
    context 'for 2008 and up' do
      
      # These data types always come back as SYBTEXT and there is no way I can 
      # find out the column's human readable name. 
      # 
      #   * [date]
      #   * [datetime2]
      #   * [datetimeoffset]
      #   * [time]
      # 
      # I have tried the following and I only get back either "char" or 0/null.
      # 
      #   rb_warn("SYBTEXT: dbprtype: %s", dbprtype(coltype));
      #   rb_warn("SYBTEXT: dbcolutype: %s", dbcolutype(rwrap->client, col));
      #   rb_warn("SYBTEXT: dbcolutype: %ld", dbcolutype(rwrap->client, col));
      
      # should 'cast date' do
      #   value = find_value 51, :date
      #   assert_equal '', value
      # end
      # 
      # should 'cast datetime2' do
      #   value = find_value 72, :datetime2_7
      #   assert_equal '', value
      # end
      # 
      # should 'cast datetimeoffset' do
      #   value = find_value 81, :datetimeoffset_2
      #   assert_equal '', value
      # end
      # 
      # should 'cast geography' do
      #   value = find_value 111, :geography
      #   assert_equal '', value
      # end
      # 
      # should 'cast geometry' do
      #   value = find_value 121, :geometry
      #   assert_equal '', value
      # end
      # 
      # should 'cast hierarchyid' do
      #   value = find_value 131, :hierarchyid
      #   assert_equal '', value
      # end
      # 
      # should 'cast time' do
      #   value = find_value 283, :time_7
      #   assert_equal '', value
      # end
      
    end if sqlserver_2008? || sqlserver_azure?
  
  end
  
  
  
end





