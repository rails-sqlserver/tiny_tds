require 'test_helper'

class ClientTest < TinyTds::TestCase
  
  
  context 'With valid credentials' do
    
    setup do
      @client = TinyTds::Client.new(connection_options)
    end
    
    should 'have a getters for the tds version information (brittle since conf takes precedence)' do
      assert_equal 9, @client.tds_version
      assert_equal 'DBTDS_8_0 - Microsoft SQL Server 2000', @client.tds_version_info
    end

  end
  
  context 'With in-valid options' do

    should 'raise an argument error when no :username is supplied' do
      assert_raise(ArgumentError) { TinyTds::Client.new :username => nil }
    end
    
    should 'raise TinyTds exception with unreachable :host' do
      options = connection_options.merge :login_timeout => 1, :host => '127.0.0.2'
      action = lambda { TinyTds::Client.new(options) }
      assert_raise_tinytds_error(action) do |e|
        assert_match %r{unable to (open|connect)}i, e.message
        assert_equal 9, e.severity
        assert [20008,20009].include?(e.db_error_number)
        assert_equal 36, e.os_error_number
      end
    end
    
    should 'raise TinyTds exception with wrong :username' do
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

