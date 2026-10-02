require "test_helper"
require "benchmark"

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

    # Baseline for https://github.com/rails-sqlserver/tiny_tds/pull/607:
    # with dbcancel as the nogvl UBF, Thread#kill aborts WAITFOR and join
    # finishes quickly. Compare to fix/null-nogvl-ubf where join waits ~5s.
    it "Thread#kill aborts an in-flight batch with dbcancel UBF" do
      skip if sqlserver_azure?

      client = new_connection
      assert_client_works(client)

      thread = Thread.new do
        client.execute("waitfor delay '00:00:05'").do
      end

      sleep 0.1

      kill_time = Benchmark.measure do
        thread.kill
      end

      join_time = Benchmark.measure do
        thread.join
      end

      puts "Thread#kill real=#{kill_time.real.round(3)}s join real=#{join_time.real.round(3)}s"

      assert kill_time.real < 5, "Thread#kill took #{kill_time.real}s"
      assert join_time.real < 1, "expected UBF cancel; join took #{join_time.real}s"
    ensure
      close_client(client) if defined?(client)
    end
  end
end
