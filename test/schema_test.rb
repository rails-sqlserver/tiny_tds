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
      
      should 'cast image' do
        assert_equal @gif1px, find_value(141,:image)
      end
      
      should 'cast int' do
        assert_equal -2147483647, find_value(151,:int)
        assert_equal 2147483646, find_value(152,:int)
      end

    end
    
    context 'for 2005 and up' do

    end
    
    context 'for 2008 and up' do
      
    end
  
  end
  
  
  protected
  
  def load_current_schema
    @current_schema_loaded ||= begin
      loader = TinyTds::Client.new(connection_options)
      schema_file = File.expand_path File.join(File.dirname(__FILE__), 'schema', "#{current_schema}.sql")
      schema_sql = File.read(schema_file)
      loader.execute(schema_sql).cancel
      loader.close
    end
  end
  
  def find_value(id, column)
    sql = "SELECT [#{column}] FROM [datatypes] WHERE [id] = #{id}"
    @client.execute(sql).first[column.to_s]
  end
  
  
end





