# encoding: utf-8
require 'test_helper'

class ResultTest < TinyTds::TestCase
  
  context 'Basic query and result' do
  
    setup do
      @@current_schema_loaded ||= load_current_schema
      @client = new_connection
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
      result.each
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
      rollback_transaction(@client) do
        text = 'test insert and delete'
        @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] IS NOT NULL").do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        row = @client.execute("SELECT [varchar_50] FROM [datatypes] WHERE [varchar_50] IS NOT NULL").each.first
        assert row
        assert_equal text, row['varchar_50']
      end
    end
        
    should 'insert and find unicode data' do
      rollback_transaction(@client) do
        text = '✓'
        @client.execute("DELETE FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").do
        @client.execute("INSERT INTO [datatypes] ([nvarchar_50]) VALUES (N'#{text}')").do
        row = @client.execute("SELECT [nvarchar_50] FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").each.first
        assert_equal text, row['nvarchar_50']
      end
    end
    
    should 'delete and update with affected rows support and insert with identity support in native sql' do
      rollback_transaction(@client) do
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
    end
    
    should 'have a #do method that cancels result rows and returns affected rows natively' do
      rollback_transaction(@client) do
        text = 'test affected rows native'
        count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
        deleted_rows = @client.execute("DELETE FROM [datatypes]").do
        assert_equal count, deleted_rows, 'should have deleted rows equal to count'
        inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        assert_equal 1, inserted_rows, 'should have inserted row for one above'
        updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        assert_equal 1, updated_rows, 'should have updated row for one above' unless sqlserver_2000? # Will report -1
      end
    end
    
    should 'allow native affected rows using #do to work under transaction' do
      rollback_transaction(@client) do
        text = 'test affected rows native in transaction'
        @client.execute("BEGIN TRANSACTION").do
        @client.execute("DELETE FROM [datatypes]").do
        inserted_rows = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        assert_equal 1, inserted_rows, 'should have inserted row for one above'
        updated_rows = @client.execute("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'").do
        assert_equal 1, updated_rows, 'should have updated row for one above' unless sqlserver_2000? # Will report -1
      end
    end
    
    should 'have an #insert method that cancels result rows and returns the SCOPE_IDENTITY() natively' do
      rollback_transaction(@client) do
        text = 'test scope identity rows native'
        @client.execute("DELETE FROM [datatypes] WHERE [varchar_50] = '#{text}'").do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").do
        sql_identity = @client.execute("SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident").each.first['Ident']
        native_identity = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')").insert
        assert_equal sql_identity+1, native_identity
      end
    end
  
    should 'return bigint for #insert when needed' do
      return if sqlserver_azure? # We can not alter clustered index like this test does.
      rollback_transaction(@client) do
        seed = 9223372036854775805
        @client.execute("DELETE FROM [datatypes]").do
        id_constraint_name = @client.execute("EXEC sp_helpindex [datatypes]").detect{ |row| row['index_keys'] == 'id' }['index_name']
        @client.execute("ALTER TABLE [datatypes] DROP CONSTRAINT [#{id_constraint_name}]").do
        @client.execute("ALTER TABLE [datatypes] DROP COLUMN [id]").do
        @client.execute("ALTER TABLE [datatypes] ADD [id] [bigint] NOT NULL IDENTITY(1,1) PRIMARY KEY").do
        @client.execute("DBCC CHECKIDENT ('datatypes', RESEED, #{seed})").do
        identity = @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('something')").insert
        assert_equal seed, identity
      end
    end
    
    should 'be able to begin/commit transactions with raw sql' do
      rollback_transaction(@client) do
        @client.execute("BEGIN TRANSACTION").do
        @client.execute("DELETE FROM [datatypes]").do
        @client.execute("COMMIT TRANSACTION").do
        count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
        assert_equal 0, count
      end
    end
    
    should 'be able to begin/rollback transactions with raw sql' do
      load_current_schema
      @client.execute("BEGIN TRANSACTION").do
      @client.execute("DELETE FROM [datatypes]").do
      @client.execute("ROLLBACK TRANSACTION").do
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").each.first['count']
      0.wont_equal count
    end
    
    should 'have a #fields accessor with logic default and valid outcome' do
      result = @client.execute(@query1)
      result.fields.must_equal ['one']
      result.each
      result.fields.must_equal ['one']
    end
    
    should 'always return an array for fields for all sql' do
      result = @client.execute("USE [tinytdstest]")
      result.fields.must_equal []
      result.do
      result.fields.must_equal []
    end
    
    should 'return fields even when no results are found' do
      no_results_query = "SELECT [id], [varchar_50] FROM [datatypes] WHERE [varchar_50] = 'NOTFOUND'"
      # Fields before each.
      result = @client.execute(no_results_query)
      result.fields.must_equal ['id','varchar_50']
      result.each
      result.fields.must_equal ['id','varchar_50']
      # Each then fields
      result = @client.execute(no_results_query)
      result.each
      result.fields.must_equal ['id','varchar_50']
    end
    
    should 'allow the result to be canceled before reading' do
      result = @client.execute(@query1)
      result.cancel
      @client.execute(@query1).each
    end
    
    should 'work in tandem with the client when needing to find out if client has sql sent and result is canceled or not' do
      # Default state.
      @client = TinyTds::Client.new(connection_options)
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal false
      # With active result before and after cancel. 
      result = @client.execute(@query1)
      @client.sqlsent?.must_equal true
      @client.canceled?.must_equal false
      result.cancel
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal true
      assert result.cancel, 'must be safe to call again'
      # With each and no block.
      @client.execute(@query1).each
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal false
      # With each and block.
      @client.execute(@query1).each do |row|
        @client.sqlsent?.must_equal true, 'when iterating over each row in a block'
        @client.canceled?.must_equal false
      end
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal false
      # With each and block canceled half way thru.
      count = @client.execute("SELECT COUNT([id]) AS [count] FROM [datatypes]").each[0]['count']
      assert count > 10, 'since we want to cancel early for test'
      result = @client.execute("SELECT [id] FROM [datatypes]")
      index = 0
      result.each do |row| 
        break if index > 10
        index += 1
      end
      @client.sqlsent?.must_equal true
      @client.canceled?.must_equal false
      result.cancel
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal true
      # With do method.
      @client.execute(@query1).do
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal true
      # With insert method.
      rollback_transaction(@client) do
        @client.execute("INSERT INTO [datatypes] ([varchar_50]) VALUES ('test')").insert
        @client.sqlsent?.must_equal false
        @client.canceled?.must_equal true
      end
      # With first
      @client.execute("SELECT [id] FROM [datatypes]").each(:first => true)
      @client.sqlsent?.must_equal false
      @client.canceled?.must_equal true
    end
    
    should 'use same string object for hash keys' do
      data = @client.execute("SELECT [id], [bigint] FROM [datatypes]").each
      assert_equal data.first.keys.map{ |r| r.object_id }, data.last.keys.map{ |r| r.object_id }
    end
    
    should 'have properly encoded column names with symbol keys' do
      col_name = "öäüß"
      @client.execute("DROP TABLE [test_encoding]").do rescue nil
      @client.execute("CREATE TABLE [dbo].[test_encoding] ( [#{col_name}] [nvarchar](10) NOT NULL )").do
      @client.execute("INSERT INTO [test_encoding] ([#{col_name}]) VALUES (N'#{col_name}')").do
      result = @client.execute("SELECT [#{col_name}] FROM [test_encoding]")
      row = result.each(:as => :hash, :symbolize_keys => true).first
      assert_instance_of Symbol, result.fields.first
      assert_equal col_name.to_sym, result.fields.first
      assert_instance_of Symbol, row.keys.first
      assert_equal col_name.to_sym, row.keys.first
    end unless sqlserver_azure?
    
    should 'allow #return_code to work with stored procedures and reset per sql batch' do
      assert_nil @client.return_code
      result = @client.execute("EXEC tinytds_TestReturnCodes")
      assert_equal [{"one"=>1}], result.each
      assert_equal 420, @client.return_code
      assert_equal 420, result.return_code
      result = @client.execute('SELECT 1 as [one]')
      result.each
      assert_nil @client.return_code
      assert_nil result.return_code
    end
    
    context 'with multiple result sets' do
  
      setup do
        @empty_select  = "SELECT 1 AS [rs1] WHERE 1 = 0"
        @double_select = "SELECT 1 AS [rs1]
                          SELECT 2 AS [rs2]" 
        @triple_select_1st_empty = "SELECT 1 AS [rs1] WHERE 1 = 0
                                    SELECT 2 AS [rs2]
                                    SELECT 3 AS [rs3]"
        @triple_select_2nd_empty = "SELECT 1 AS [rs1]
                                    SELECT 2 AS [rs2] WHERE 1 = 0
                                    SELECT 3 AS [rs3]"
        @triple_select_3rd_empty = "SELECT 1 AS [rs1]
                                    SELECT 2 AS [rs2]
                                    SELECT 3 AS [rs3] WHERE 1 = 0"
      end
      
      should 'handle a command buffer with double selects' do
        result = @client.execute(@double_select)
        result_sets = result.each
        assert_equal 2, result_sets.size
        assert_equal [{'rs1' => 1}], result_sets.first
        assert_equal [{'rs2' => 2}], result_sets.last
        assert_equal [['rs1'], ['rs2']], result.fields
        assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        # As array
        result = @client.execute(@double_select)
        result_sets = result.each(:as => :array)
        assert_equal 2, result_sets.size
        assert_equal [[1]], result_sets.first
        assert_equal [[2]], result_sets.last
        assert_equal [['rs1'], ['rs2']], result.fields
        assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
      end
      
      should 'yield each row for each result set' do
        data = []
        result_sets = @client.execute(@double_select).each { |row| data << row }
        assert_equal data.first, result_sets.first[0]
        assert_equal data.last, result_sets.last[0]
      end
      
      should 'from a stored procedure' do
        if sqlserver?
          results1, results2 = @client.execute("EXEC sp_helpconstraint '[datatypes]'").each
          assert_equal [{"Object Name"=>"[datatypes]"}], results1
          constraint_info = results2.first
          assert constraint_info.key?("constraint_keys")
          assert constraint_info.key?("constraint_type")
          assert constraint_info.key?("constraint_name")
        elsif sybase_ase?
          results1, results2 = @client.execute("EXEC sp_helpconstraint 'datatypes'").each
          assert results1['name']      =~ /^datatypes_bit/
          assert results1['defintion'] == 'DEFAULT  0'
          assert results2['name']      =~ /^datatypes_id/
          assert results2['defintion'] =~ /^PRIMARY KEY/
        end
      end

      context 'using :empty_sets TRUE' do
        
        setup do
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = true
          @client = new_connection
        end
        
        teardown do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end
        
        should 'handle a basic empty result set' do
          result = @client.execute(@empty_select)
          assert_equal [], result.each
          assert_equal ['rs1'], result.fields
        end
  
        should 'include empty result sets by default - using 1st empty buffer' do
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [], result_sets[0]
          assert_equal [{'rs2' => 2}], result_sets[1]
          assert_equal [{'rs3' => 3}], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each(:as => :array)
          assert_equal 3, result_sets.size
          assert_equal [], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [[3]], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
  
        should 'include empty result sets by default - using 2nd empty buffer' do
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [{'rs1' => 1}], result_sets[0]
          assert_equal [], result_sets[1]
          assert_equal [{'rs3' => 3}], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each(:as => :array)
          assert_equal 3, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [], result_sets[1]
          assert_equal [[3]], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
  
        should 'include empty result sets by default - using 3rd empty buffer' do
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each
          assert_equal 3, result_sets.size
          assert_equal [{'rs1' => 1}], result_sets[0]
          assert_equal [{'rs2' => 2}], result_sets[1]
          assert_equal [], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each(:as => :array)
          assert_equal 3, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [], result_sets[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
  
      end
      
      context 'using :empty_sets FALSE' do
        
        setup do
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = false
          @client = new_connection
        end
        
        teardown do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end
        
        should 'handle a basic empty result set' do
          result = @client.execute(@empty_select)
          assert_equal [], result.each
          assert_equal ['rs1'], result.fields
        end
        
        should 'not include empty result sets by default - using 1st empty buffer' do
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{'rs2' => 2}], result_sets[0]
          assert_equal [{'rs3' => 3}], result_sets[1]
          assert_equal [['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_1st_empty)
          result_sets = result.each(:as => :array)
          assert_equal 2, result_sets.size
          assert_equal [[2]], result_sets[0]
          assert_equal [[3]], result_sets[1]
          assert_equal [['rs2'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
        
        should 'not include empty result sets by default - using 2nd empty buffer' do
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{'rs1' => 1}], result_sets[0]
          assert_equal [{'rs3' => 3}], result_sets[1]
          assert_equal [['rs1'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_2nd_empty)
          result_sets = result.each(:as => :array)
          assert_equal 2, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[3]], result_sets[1]
          assert_equal [['rs1'], ['rs3']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
  
        should 'not include empty result sets by default - using 3rd empty buffer' do
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each
          assert_equal 2, result_sets.size
          assert_equal [{'rs1' => 1}], result_sets[0]
          assert_equal [{'rs2' => 2}], result_sets[1]
          assert_equal [['rs1'], ['rs2']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
          # As array
          result = @client.execute(@triple_select_3rd_empty)
          result_sets = result.each(:as => :array)
          assert_equal 2, result_sets.size
          assert_equal [[1]], result_sets[0]
          assert_equal [[2]], result_sets[1]
          assert_equal [['rs1'], ['rs2']], result.fields
          assert_equal result.each.object_id, result.each.object_id, 'same cached rows'
        end
  
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
    
    context 'with data type' do

      context 'char max' do

        setup do
          @big_text = 'x' * 2_000_000
          @old_textsize = @client.execute("SELECT @@TEXTSIZE AS [textsize]").each.first['textsize'].inspect
          @client.execute("SET TEXTSIZE #{(@big_text.length*2)+1}").do
        end

        should 'insert and select large varchar_max' do
          insert_and_select_datatype :varchar_max
        end

        should 'insert and select large nvarchar_max' do
          insert_and_select_datatype :nvarchar_max
        end

      end unless sqlserver_2000? || sybase_ase?

    end
    
    context 'when shit happens' do
      
      should 'cope with nil or empty buffer' do
        assert_raises(TypeError) { @client.execute(nil) } 
        assert_equal [], @client.execute('').each
      end
      
      if sybase_ase?

        should 'not raise an error when severity is 10 or less' do
          (1..10).to_a.each do |severity|
            @client.execute("RAISERROR(N'Test #{severity} severity', #{severity}, 1)").do
          end
        end

        should 'raise an error when severity is greater than 10' do
          action = lambda { @client.execute("RAISERROR(N'Test 11 severity', 11, 1)").do }
          assert_raise_tinytds_error(action) do |e|
            assert_equal "Test 11 severity", e.message
            assert_equal 11, e.severity
            assert_equal 50000, e.db_error_number
          end
        end

      else

        should 'raise an error' do
          action = lambda { @client.execute("RAISERROR 99999 'Hello World'").do }
          assert_raise_tinytds_error(action) do |e|
            assert_equal "Hello World", e.message
            assert_equal 16, e.severity # predefined on ASE
            assert_equal 99999, e.db_error_number
          end
        end

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
      
      should 'error gracefully with incorrect syntax' do
        action = lambda { @client.execute('this will not work').each }
        assert_raise_tinytds_error(action) do |e|
          assert_match %r|incorrect syntax|i, e.message
          assert_equal 15, e.severity
          assert_equal 156, e.db_error_number
        end
        assert_followup_query
      end
      
      should 'error gracefully with incorrect syntax in sp_executesql' do
        if @client.freetds_091_or_higer?
          action = lambda { @client.execute("EXEC sp_executesql N'this will not work'").each }
          assert_raise_tinytds_error(action) do |e|
            assert_match %r|incorrect syntax|i, e.message
            assert_equal 15, e.severity
            assert_equal 156, e.db_error_number
          end
          assert_followup_query
        else
          skip 'FreeTDS 0.91 and higher can only pass this test.'
        end
      end
    
    end

  end
  
  
  protected
  
  def assert_followup_query
    result = @client.execute(@query1)
    assert_equal 1, result.each.first['one']
  end
  
  def insert_and_select_datatype(datatype)
    rollback_transaction(@client) do
      @client.execute("DELETE FROM [datatypes] WHERE [#{datatype}] IS NOT NULL").do
      id = @client.execute("INSERT INTO [datatypes] ([#{datatype}]) VALUES (N'#{@big_text}')").insert
      found_text = find_value id, datatype
      flunk "Large #{datatype} data with a length of #{@big_text.length} did not match found text with length of #{found_text.length}" unless @big_text == found_text
    end
  end
  
end

