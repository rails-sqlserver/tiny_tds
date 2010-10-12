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
    
    should 'allow successive calls to each returning the same data' do
      result = @client.execute(@query1)
      data = result.each
      assert_nothing_raised() { result.each }
      assert_equal data.object_id, result.each.object_id
      assert_equal data.first.object_id, result.each.first.object_id
    end
    
    should 'return hashes with string keys' do
      result = @client.execute(@query1)
      row = result.each(:as => :hash, :symbolize_keys => false).first
      assert_instance_of Hash, row
      assert_equal ['one'], row.keys
      assert_equal ['one'], result.fields
    end
    
    should 'return hashes with symbol keys' do
      result = @client.execute(@query1)
      row = result.each(:as => :hash, :symbolize_keys => true).first
      assert_instance_of Hash, row
      assert_equal [:one], row.keys
      assert_equal [:one], result.fields
    end
    
    should 'return arrays with string fields' do
      result = @client.execute(@query1)
      row = result.each(:as => :array, :symbolize_keys => false).first
      assert_instance_of Array, row
      assert_equal ['one'], result.fields
    end
    
    should 'return arrays with symbol fields' do
      result = @client.execute(@query1)
      row = result.each(:as => :array, :symbolize_keys => true).first
      assert_instance_of Array, row
      assert_equal [:one], result.fields
    end
    
    should 'be able to turn :cache_rows option off' do
      result = @client.execute(@query1)
      local = []
      result.each(:cache_rows => false) do |row|
        local << row
      end
      assert local.first, 'should have iterated over each row'
      assert_equal [], result.each, 'should not have been cached'
      assert_equal ['one'], result.fields, 'should still cache field names'
    end
    
    should 'have a #fields accessor with logic default and valid outcome' do
      result = @client.execute(@query1)
      assert_nil result.fields
      result.each
      assert_instance_of Array, result.fields
    end
    
    should 'allow the result to be canceled before reading' do
      result = @client.execute(@query1)
      result.cancel
      assert_nothing_raised() { @client.execute(@query1).each }
    end
    
    should 'use same string object for hash keys' do
      data = @client.execute("SELECT [id], [bigint] FROM [datatypes]").each
      assert_equal data.first.keys.map{ |r| r.object_id }, data.last.keys.map{ |r| r.object_id }
    end
    
    context 'when casting to native ruby values' do
    
      should 'return fixnum for 1' do
        value = @client.execute('SELECT 1 AS [fixnum]').each.first['fixnum']
        assert_equal 1, value
      end
      
      should 'return nil for NULL' do
        value = @client.execute('SELECT NULL AS [null]').each.first['null']
        assert_equal nil, value
      end
    
    end
    
    context 'when shit happens' do
      
      should 'cope with nil or empty buffer' do
        assert_raise(TypeError) { @client.execute(nil) } 
        assert_equal [], @client.execute('').each
      end
      
      should 'throw an error when you execute another query with other results pending' do
        result1 = @client.execute(@query1)
        action = lambda { @client.execute(@query1) }
        assert_raise_tinytds_error(action) do |e|
          assert_match %r|with results pending|i, e.message
          assert_equal 7, e.severity
          assert_equal 20019, e.db_error_number
        end
      end

      should 'error gracefully with bad table name' do
        assert_raise_tinytds_error(lambda{ @client.execute('SELECT * FROM [foobar]') }) do |e|
          assert_match %r|invalid object name.*foobar|i, e.message
          assert_equal 16, e.severity
          assert_equal 208, e.db_error_number
        end
        assert_followup_query
      end
      
      should 'error gracefully with invalid syntax' do        
        assert_raise_tinytds_error(lambda{ @client.execute('this will not work') }) do |e|
          assert_match %r|incorrect syntax|i, e.message
          assert_equal 15, e.severity
          assert_equal 156, e.db_error_number
        end
        assert_followup_query
      end

    end

  end
  
  
  protected
  
  def assert_followup_query
    assert_nothing_raised do
      result = @client.execute(@query1)
      assert_equal 1, result.each.first['one']
    end
  end
  
end

