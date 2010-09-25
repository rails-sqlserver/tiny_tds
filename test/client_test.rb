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
    
    should 'fail as expected with wrong username' do
      options = connection_options.merge :username => 'willnotwork'
      action = lambda { TinyTds::Client.new(options) }
      assert_raise_tinytds_error(action) do |e|
        assert_match(/login failed/i, e.message)
        assert_equal 14, e.severity
        assert_equal 18456, e.db_error_number
        assert_equal 1, e.os_error_number
      end
    end

  end
  
  
  
end

