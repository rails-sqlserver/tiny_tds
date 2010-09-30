require 'test_helper'

class SchemaTest < TinyTds::TestCase
  
  context 'With specific schema' do
  
    setup do
      load_current_schema
    end
  
    should '' do
      
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
  
  
end





