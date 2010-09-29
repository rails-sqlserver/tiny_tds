require 'test_helper'

class ResultTest < TinyTds::TestCase
  
  context 'Basic query and result' do

    setup do
      @client = TinyTds::Client.new(connection_options)
      @query1 = 'SELECT 1 AS [one]'
    end
    
    should 'have included Enumerable' do
      assert TinyTds::Result.ancestors.include?(Enumerable)
    end
    
    should 'respond to #each' do
      result = @client.execute(@query1)
      assert result.respond_to?(:each)
    end
    
    should 'return all results for #each with no block' do
      result = @client.execute(@query1)
      data = result.each
      row = data.first
      assert_instance_of Array, data
      assert_equal 1, data.size
      assert_instance_of Hash, row, 'hash is the default query option'
    end
    
    should 'return all results for #each with a block yielding a row at a time' do
      result = @client.execute(@query1)
      data = result.each do |row|
        assert_instance_of Hash, row, 'hash is the default query option'
      end
      assert_instance_of Array, data
    end

  end
  
  
end

