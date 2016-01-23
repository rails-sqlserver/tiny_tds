require 'test_helper'
require 'logger'
require 'benchmark'

class ThreadTest < TinyTds::TestCase

  describe 'Threaded SELECT queries' do

    before do
      @logger = Logger.new $stdout
      @logger.level = Logger::WARN
      @poolsize = 4
      @numthreads = 10
      @query = "waitfor delay '00:00:01'"
      @pool = ConnectionPool.new(:size => @poolsize, :timeout => 5) { new_connection }
    end

    after do
      @pool.shutdown { |c| c.close }
    end

    it 'should finish faster in parallel' do
      skip if sqlserver_azure?
      x = Benchmark.realtime do
        threads = []
        @numthreads.times do |i|
          start = Time.new
          threads << Thread.new do
            ts = Time.new
            @pool.with { |c| c.execute(@query).do }
            te = Time.new
            @logger.info "Thread #{i} finished in #{te - ts} thread seconds, #{te - start} real seconds"
          end
        end
        threads.each { |t| t.join }
      end
      assert x < @numthreads, "#{x} is not faster than #{@numthreads} seconds"
      mintime = (1.0*@numthreads/@poolsize).ceil
      @logger.info "#{@numthreads} queries on #{@poolsize} threads: #{x} sec. Minimum time: #{mintime} sec."
      assert x > mintime, "#{x} is not slower than #{mintime} seconds"
    end

    it 'should not crash on error in parallel' do
      skip if sqlserver_azure?
      threads = []
      @numthreads.times do |i|
        threads << Thread.new do
          @pool.with do |client|
            begin
              result = client.execute "select dbname()"
              result.each { |r| puts r }
            rescue Exception => e
              # We are throwing an error on purpose here since 0.6.1 would
              # segfault on errors thrown in threads
            end
          end
        end
      end
      threads.each { |t| t.join }
      assert true
    end

    it 'should cancel when hitting timeout in thread' do
      exception = false

      thread = Thread.new do
        @pool.with do |client|
          begin
            delay = ('0' + (connection_timeout + 2).to_s)[-2,2] # Two seconds longer than default.
            result = client.execute "waitfor delay '00:00:#{delay}'; select db_name()"
            result.each { |r| puts r }
          rescue TinyTds::Error => e
            if e.message == 'Adaptive Server connection timed out'
              exception = true
            end
          end
        end
      end

      timer_thread = Thread.new do
        # Sleep until after the timeout should have been reached
        sleep(connection_timeout+2)
        if not exception
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

