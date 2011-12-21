require 'test_helper'

class ClientTest < TinyTds::TestCase
  
  context 'With valid credentials' do
    
    setup do
      @client = new_connection
    end

    should 'not be closed' do
      assert !@client.closed?
      assert @client.active?
    end
    
    should 'allow client connection to be closed' do
      assert @client.close
      assert @client.closed?
      assert !@client.active?
      action = lambda { @client.execute('SELECT 1 as [one]').each }
      assert_raise_tinytds_error(action) do |e|
        assert_match %r{closed connection}i, e.message, 'ignore if non-english test run'
      end
    end
    
    should 'have a getters for the tds version information (brittle since conf takes precedence)' do
      assert_equal 9, @client.tds_version
      assert_equal 'DBTDS_7_1 - Microsoft SQL Server 2000', @client.tds_version_info
    end
    
    should 'use UTF-8 client charset/encoding by default' do
      assert_equal 'UTF-8', @client.charset
      assert_equal Encoding.find('UTF-8'), @client.encoding if ruby19?
    end
    
    should 'have a #escape method used for quote strings' do
      assert_equal "''hello''", @client.escape("'hello'")
    end
    
    should 'allow valid iconv character set' do
      ['CP850', 'CP1252', 'ISO-8859-1'].each do |encoding|
        client = new_connection(:encoding => encoding)
        assert_equal encoding, client.charset
        assert_equal Encoding.find(encoding), client.encoding if ruby19?
      end
    end
    
    should 'be able to use :host/:port connection' do
      client = new_connection :dataserver => nil, :host => ENV['TINYTDS_UNIT_HOST'], :port => ENV['TINYTDS_UNIT_PORT'] || 1433
    end unless sqlserver_azure?
  
  end
  
  context 'With in-valid options' do
    
    should 'raise an argument error when no :host given and :dataserver is blank' do
      assert_raises(ArgumentError) { new_connection :dataserver => nil, :host => nil }
    end
    
    should 'raise an argument error when no :username is supplied' do
      assert_raises(ArgumentError) { TinyTds::Client.new :username => nil }
    end
    
    should 'raise TinyTds exception with undefined :dataserver' do
      options = connection_options :login_timeout => 1, :dataserver => '127.0.0.2'
      action = lambda { new_connection(options) }
      assert_raise_tinytds_error(action) do |e|
        assert [20008,20009].include?(e.db_error_number)
        assert_equal 9, e.severity
        assert_match %r{unable to (open|connect)}i, e.message, 'ignore if non-english test run'
      end
      assert_new_connections_work
    end
    
    should 'raise TinyTds exception with long query past :timeout option' do
      client = new_connection :timeout => 1
      action = lambda { client.execute("WaitFor Delay '00:00:02'").do }
      assert_raise_tinytds_error(action) do |e|
        assert_equal 20003, e.db_error_number
        assert_equal 6, e.severity
        assert_match %r{timed out}i, e.message, 'ignore if non-english test run'
      end
      assert_client_works(client)
      assert_new_connections_work
    end
    
    should 'not timeout per sql batch when not under transaction' do
      client = new_connection :timeout => 2
      client.execute("WaitFor Delay '00:00:01'").do
      client.execute("WaitFor Delay '00:00:01'").do
      client.execute("WaitFor Delay '00:00:01'").do
    end
    
    should 'not timeout per sql batch when under transaction' do
      client = new_connection :timeout => 2
      begin
        client.execute("BEGIN TRANSACTION").do
        client.execute("WaitFor Delay '00:00:01'").do
        client.execute("WaitFor Delay '00:00:01'").do
        client.execute("WaitFor Delay '00:00:01'").do
      ensure
        client.execute("COMMIT TRANSACTION").do
      end
    end
    
    should_eventually 'run this test to prove we account for dropped connections' do
      begin
        client = new_connection :login_timeout => 2, :timeout => 2
        assert_client_works(client)
        STDOUT.puts "Disconnect network!"
        sleep 10
        STDOUT.puts "This should not get stuck past 6 seconds!"
        action = lambda { client.execute('SELECT 1 as [one]').each }
        assert_raise_tinytds_error(action) do |e|
          assert_equal 20003, e.db_error_number
          assert_equal 6, e.severity
          assert_match %r{timed out}i, e.message, 'ignore if non-english test run'
        end
      ensure
        STDOUT.puts "Reconnect network!"
        sleep 10
        action = lambda { client.execute('SELECT 1 as [one]').each }
        assert_raise_tinytds_error(action) do |e|
          assert_equal 20047, e.db_error_number
          assert_equal 1, e.severity
          assert_match %r{dead or not enabled}i, e.message, 'ignore if non-english test run'
        end
        assert_new_connections_work
      end
    end
    
    should 'raise TinyTds exception with wrong :username' do
      options = connection_options :username => 'willnotwork'
      action = lambda { new_connection(options) }
      assert_raise_tinytds_error(action) do |e|
        if sqlserver_azure?
          assert_match %r{server name cannot be determined}i, e.message, 'ignore if non-english test run'
        else
          assert_equal sybase_ase? ? 4002 : 18456, e.db_error_number
          assert_equal 14, e.severity
          assert_match %r{login failed}i, e.message, 'ignore if non-english test run'
        end
      end
      assert_new_connections_work
    end
    
    should 'fail miserably with unknown encoding option' do
      options = connection_options :encoding => 'ISO-WTF'
      action = lambda { new_connection(options) }
      assert_raise_tinytds_error(action) do |e|
        assert_equal 20002, e.db_error_number
        assert_equal 9, e.severity
        assert_match %r{connection failed}i, e.message, 'ignore if non-english test run'
      end
      assert_new_connections_work
    end
  
  end
  
  
  
end

