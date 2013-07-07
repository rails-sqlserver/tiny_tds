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

    it 'should finish faster in parallel' do
      x = Benchmark.realtime do
        threads = []
        @numthreads.times do |i|
          start = Time.new
          threads << Thread.new do
            ts = Time.new
            @pool.with do |client|
              result = client.execute @query
              result.each { |r| puts r }
            end
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

  end

end

