require "test_helper"
require "benchmark"
require "socket"

class ThreadTest < TinyTds::TestCase
  describe "Threaded SELECT queries" do
    before do
      @poolsize = 4
      @numthreads = 10
      @query = "waitfor delay '00:00:01'"
      @pool = ConnectionPool.new(size: @poolsize, timeout: 5) { new_connection }
    end

    after do
      @pool.shutdown { |c| c.close }
    end

    it "runs queries and their message handlers while another connection is logging in" do
      messages = []
      client = new_connection(message_handler: proc { |message| messages << message.message })
      messages.clear
      server = TCPServer.new("127.0.0.1", 0)
      login = Thread.new do
        new_connection(dataserver: nil, host: "127.0.0.1", port: server.addr[1], login_timeout: 5)
      rescue TinyTds::Error => error
        error
      end
      peer = server.accept
      GC.start
      GC.compact if GC.respond_to?(:compact)
      client.execute("PRINT 'query during login'").do
      assert_client_works(client)
      assert_equal ["query during login"], messages
      assert login.alive?, "the query waited for the unrelated login to finish"
    ensure
      peer&.close
      server&.close
      login&.join
      close_client(client)
    end

    it "should finish faster in parallel" do
      skip if sqlserver_azure?
      x = Benchmark.realtime do
        threads = []
        @numthreads.times do |i|
          threads << Thread.new do
            @pool.with { |c| c.execute(@query).do }
          end
        end
        threads.each { |t| t.join }
      end
      assert x < @numthreads, "#{x} is not faster than #{@numthreads} seconds"
      mintime = (1.0 * @numthreads / @poolsize).ceil
      assert x > mintime, "#{x} is not slower than #{mintime} seconds"
    end

    it "should not crash on error in parallel" do
      skip if sqlserver_azure?
      threads = []
      @numthreads.times do |i|
        threads << Thread.new do
          @pool.with do |client|
            result = client.execute "select dbname()"
            result.each { |r| puts r }
          rescue => _e
            # We are throwing an error on purpose here since 0.6.1 would
            # segfault on errors thrown in threads
          end
        end
      end
      threads.each { |t| t.join }
      assert true
    end

    it "should cancel when hitting timeout in thread" do
      exception = false

      thread = Thread.new do
        @pool.with do |client|
          delay = ("0" + (connection_timeout + 2).to_s)[-2, 2] # Two seconds longer than default.
          result = client.execute "waitfor delay '00:00:#{delay}'; select db_name()"
          result.each { |r| puts r }
        rescue TinyTds::Error => e
          if e.message.include?("connection timed out")
            exception = true
          end
        end
      end

      timer_thread = Thread.new do
        # Sleep until after the timeout should have been reached
        sleep(connection_timeout + 2)
        if !exception
          thread.kill
          raise "Timeout passed without query timing out"
        end
      end

      thread.join
      timer_thread.join

      assert exception
    end
  end
end
