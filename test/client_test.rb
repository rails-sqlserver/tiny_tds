require 'test_helper'

class ClientTest < TinyTds::TestCase
  
  
  context 'With valid credentials to client' do
    
    setup do
      @client = TinyTds::Client.new(connection_options)
    end
    
    should '' do
      
    end

  end
  
  
end

