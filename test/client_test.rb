require 'test_helper'

class ClientTest < TinyTds::TestCase
  
  
  context 'With valid credentials' do
    
    setup do
      @client = TinyTds::Client.new(connection_options)
    end
    
    should '' do
      
    end

  end
  
  context 'With in-valid credentials' do

    should 'raise an argument error when no :username is supplied' do
      assert_raise(ArgumentError) { TinyTds::Client.new :username => nil }
    end

  end
  
  
  
end

