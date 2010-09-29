require 'test_helper'

class SchemaTest < TinyTds::TestCase
  
  context 'With specific schema' do

    setup do
      # if !@schema_imported
      #   schema_file = File.expand_path File.join(File.dirname(__FILE__), 'schema', "#{TinyTds.current_schema}.sql")
      #   schema_sql = FIle.read(schema_file)
      #   TinyTds::Client.new(connection_options).execute(schema_sql)
      #   @schema_imported = true
      # end
    end

    should '' do
      
    end

  end
  
  
end





