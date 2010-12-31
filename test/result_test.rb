# encoding: utf-8
require 'test_helper'

class ResultTest < TinyTds::TestCase
  
  context 'Basic query and result' do

    setup do
      @@current_schema_loaded ||= load_current_schema
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
    
    should 'be able to get the first result row only' do
      load_current_schema
      big_query = "SELECT [id] FROM [datatypes]"
      one = @client.execute(big_query).each(:first => true)
      many = @client.execute(big_query).each
      assert many.size > 1
      assert one.size == 1
    end
    
    should 'cope with no results when using first option' do
      data = @client.execute("SELECT [id] FROM [datatypes] WHERE [id] = -1").each(:first => true)
      assert_equal [], data
    end
    
    should 'delete, insert and find data' do
      text = 'test insert and delete'
      @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] IS NOT NULL").do
      @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
      row = @client.execute("SELECT [varchar_50] FROM [datatypes] WHERE [varchar_50] IS NOT NULL").each.first
      assert row
      assert_equal text, row['varchar_50']
    end
    
    should 'insert and find unicode data' do
      text = '✓'
      @client.execute("DELETE FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").do
      @client.execute("INSERT INTO [datatypes] ([nvarchar_50]) VALUES (N'#{text}')").do
      row = @client.execute("SELECT [nvarchar_50] FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").each.first
      assert_equal text, row['nvarchar_50']
    end
    
    should 'delete and update with affected rows support and insert with identity support in native sql' do
      load_current_schema
      text = 'test affected rows sql'
      @client.execute("DELETE FROM [datatypes]").do
      afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").each.first['AffectedRows']
      assert_instance_of Fixnum, afrows
      @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
      pk1 = @client.execute("SELECT SCOPE_IDENTITY() AS Ident").each.first['Ident']
      assert_instance_of BigDecimal, pk1, 'native is numeric(38,0) for SCOPE_IDENTITY() function'
      pk2 = @client.execute("SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident").each.first['Ident']
      assert_instance_of Fixnum, pk2, 'we should be able to CAST to bigint'
      assert_equal pk2, pk1.to_i, 'just making sure the 2 line up'
      @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
      afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").each.first['AffectedRows']
      assert_equal 1, afrows
    end
    
    should 'have a #do method that cancels result rows and returns affected rows natively' do
      load_current_schema
      text = 'test affected rows native'
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
      deleted_rows = @client.execute("DELETE FROM [datatypes]").do
      assert_equal count, deleted_rows, 'should have deleted rows equal to count'
      inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
      assert_equal 1, inserted_rows, 'should have inserted row for one above'
      updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
      assert_equal 1, updated_rows, 'should have updated row for one above'
    end
    
    should 'allow native affected rows using #do to work under transaction' do
      load_current_schema
      text = 'test affected rows native in transaction'
      begin
        @client.execute("BEGIN TRANSACTION").do
        @client.execute("DELETE FROM [datatypes]").do
        inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        assert_equal 1, inserted_rows, 'should have inserted row for one above'
        updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        assert_equal 1, updated_rows, 'should have updated row for one above' unless sqlserver_2000? # Will report -1
      ensure
        @client.execute("COMMIT TRANSACTION").do
      end
    end
    
    should 'have an #insert method that cancels result rows and returns the SCOPE_IDENTITY() natively' do
      text = 'test scope identity rows native'
      @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] = '#{text}'").do
      @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
      sql_identity = @client.execute("SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident").each.first['Ident']
      native_identity = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").insert
      assert_equal sql_identity+1, native_identity
    end
    
    should 'be able to begin/commit transactions with raw sql' do
      load_current_schema
      @client.execute("BEGIN TRANSACTION").do
      @client.execute("DELETE FROM [datatypes]").do
      @client.execute("COMMIT TRANSACTION").do
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
      assert_equal 0, count
    end
    
    should 'be able to begin/rollback transactions with raw sql' do
      load_current_schema
      @client.execute("BEGIN TRANSACTION").do
      @client.execute("DELETE FROM [datatypes]").do
      @client.execute("ROLLBACK TRANSACTION").do
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
      assert_not_equal 0, count
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
    
    should 'have properly encoded column names' do
      col_name = "öäüß"
      @client.execute("DROP TABLE [test_encoding]").do rescue nil
      @client.execute("CREATE TABLE [test_encoding] ( [#{col_name}] [nvarchar](10) NOT NULL )").do
      @client.execute("INSERT INTO [test_encoding] ([#{col_name}]) VALUES (N'#{col_name}')").do
      result = @client.execute("SELECT [#{col_name}] FROM [test_encoding]")
      row = result.each.first
      assert_equal col_name, result.fields.first
      assert_equal col_name, row.keys.first
      assert_utf8_encoding result.fields.first
      assert_utf8_encoding row.keys.first
    end
    
    context 'with multiple result sets' do
      
      setup do
        @double_select = "SELECT 1 AS [rs1]\nSELECT 2 AS [rs2]" 
      end
      
      should 'handle a command buffer with double selects' do
        result = @client.execute(@double_select)
        result_sets = result.each
        assert_equal 2, result_sets.size
        assert_equal [{'rs1' => 1}], result_sets.first
        assert_equal [{'rs2' => 2}], result_sets.last
        assert_equal [['rs1'],['rs2']], result.fields
        assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        # As array
        result = @client.execute(@double_select)
        result_sets = result.each(:as => :array)
        assert_equal 2, result_sets.size
        assert_equal [[1]], result_sets.first
        assert_equal [[2]], result_sets.last
        assert_equal [['rs1'],['rs2']], result.fields
        assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
      end
      
      should 'yield each row for each result set' do
        data = []
        result = 
        result_sets = @client.execute(@double_select).each { |row| data << row }
        assert_equal data.first, result_sets.first[0]
        assert_equal data.last, result_sets.last[0]
      end
      
      should 'from a stored procedure' do
        results1, results2 = @client.execute("EXEC sp_helpconstraint '[datatypes]'").each
        assert_equal [{"Object Name"=>"[datatypes]"}], results1
        constraint_info = results2.first
        assert constraint_info.key?("constraint_keys")
        assert constraint_info.key?("constraint_type")
        assert constraint_info.key?("constraint_name")
      end
      
      should 'ignore empty result sets' do
        load_current_schema
        @client.execute("DELETE FROM [datatypes]").do
        id = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('test empty result sets')").insert
        sql = %|
          SET NOCOUNT ON
          DECLARE @row_number TABLE (row int identity(1,1), id int) 
          INSERT INTO @row_number (id) 
            SELECT [datatypes].[id] FROM [datatypes]
          SET NOCOUNT OFF 
          SELECT id FROM @row_number|
        assert_equal [{"id"=>id}], @client.execute(sql).each
      end

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
        action = lambda { @client.execute('SELECT * FROM [foobar]').each }
        assert_raise_tinytds_error(action) do |e|
          assert_match %r|invalid object name.*foobar|i, e.message
          assert_equal 16, e.severity
          assert_equal 208, e.db_error_number
        end
        assert_followup_query
      end
      
      should 'error gracefully with invalid syntax' do
        action = lambda { @client.execute('this will not work').each }
        assert_raise_tinytds_error(action) do |e|
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

