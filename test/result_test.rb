# encoding: utf-8
require 'test_helper'

class ResultTest < TinyTds::TestCase

  describe 'Basic query and result' do

    before do
      @@current_schema_loaded ||= load_current_schema
      @client = new_connection
      @query1 = 'SELECT 1 AS [one]'
    end

    it 'has included Enumerable' do
      assert TinyTds::Result.ancestors.include?(Enumerable)
    end

    it 'responds to #each' do
      result = @client.execute(@query1)
      assert result.respond_to?(:each)
    end

    it 'returns all results for #each with a block yielding a row at a time' do
      result = @client.execute(@query1)
      data = result.each do |row|
        assert_instance_of Hash, row, 'hash is the default query option'
      end

      assert_instance_of Array, data
    end

    it 'returns arrays' do
      results = @client.execute(@query1, as: :array)
      row = results.first
      assert_instance_of Array, row
      assert_equal ['one'], results.fields
    end

    it 'allows sql concat + to work' do
      rollback_transaction(@client) do
        @client.do("DELETE FROM [datatypes]")
        @client.do("INSERT INTO [datatypes] ([char_10], [varchar_50]) VALUES ('1', '2')")
        result = @client.execute("SELECT TOP (1) [char_10] + 'test' + [varchar_50] AS [test] FROM [datatypes]").first['test']
        _(result).must_equal "1         test2"
      end
    end

    it 'must delete, insert and find data' do
      rollback_transaction(@client) do
        text = 'test insert and delete'
        @client.do("DELETE FROM [datatypes] WHERE [varchar_50] IS NOT NULL")
        @client.do("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')")
        row = @client.execute("SELECT [varchar_50] FROM [datatypes] WHERE [varchar_50] IS NOT NULL").first
        assert row
        assert_equal text, row['varchar_50']
      end
    end

    it 'must insert and find unicode data' do
      rollback_transaction(@client) do
        text = '😍'
        @client.do("DELETE FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL")
        @client.do("INSERT INTO [datatypes] ([nvarchar_50]) VALUES (N'#{text}')")
        row = @client.execute("SELECT [nvarchar_50] FROM [datatypes] WHERE [nvarchar_50] IS NOT NULL").first
        assert_equal text, row['nvarchar_50']
      end
    end

    it 'must delete and update with affected rows support and insert with identity support in native sql' do
      rollback_transaction(@client) do
        text = 'test affected rows sql'
        @client.do("DELETE FROM [datatypes]")
        afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").first['AffectedRows']
        _(['Fixnum', 'Integer']).must_include afrows.class.name
        @client.do("INSERT INTO [datatypes] ([varchar_50]) VALUES ('#{text}')")
        pk1 = @client.execute(@client.identity_sql).first['Ident']
        _(['Fixnum', 'Integer']).must_include pk1.class.name, 'we it be able to CAST to bigint'
        @client.do("UPDATE [datatypes] SET [varchar_50] = NULL WHERE [varchar_50] = '#{text}'")
        afrows = @client.execute("SELECT @@ROWCOUNT AS AffectedRows").first['AffectedRows']
        assert_equal 1, afrows
      end
    end

    it 'must be able to begin/commit transactions with raw sql' do
      rollback_transaction(@client) do
        @client.do("BEGIN TRANSACTION")
        @client.do("DELETE FROM [datatypes]")
        @client.do("COMMIT TRANSACTION")
        count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").first['count']
        assert_equal 0, count
      end
    end

    it 'must be able to begin/rollback transactions with raw sql' do
      load_current_schema
      @client.do("BEGIN TRANSACTION")
      @client.do("DELETE FROM [datatypes]")
      @client.do("ROLLBACK TRANSACTION")
      count = @client.execute("SELECT COUNT(*) AS [count] FROM [datatypes]").first['count']
      _(count).wont_equal 0
    end

    it 'has a #fields accessor with logic default and valid outcome' do
      result = @client.execute(@query1)
      _(result.fields).must_equal ['one']
    end

    it 'always returns an array for fields for all sql' do
      result = @client.execute("USE [tinytdstest]")
      _(result.fields).must_equal []
    end

    it 'returns fields even when no results are found' do
      no_results_query = "SELECT [id], [varchar_50] FROM [datatypes] WHERE [varchar_50] = 'NOTFOUND'"
      # Fields before each.
      result = @client.execute(no_results_query)
      _(result.fields).must_equal ['id', 'varchar_50']
    end

    it 'works in tandem with the client when needing to find out if client has sql sent and result is canceled or not' do
      # Default state.
      @client = TinyTds::Client.new(connection_options)
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal false

      # With active result before and after cancel.
      result = @client.execute(@query1)
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      
      # With each and no block.
      @client.execute(@query1).each
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      
      # With each and block.
      @client.execute(@query1).each do |row|
        _(@client.sqlsent?).must_equal false
        _(@client.canceled?).must_equal true
      end
      
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
      
      # With each and block canceled half way thru.
      count = @client.execute("SELECT COUNT([id]) AS [count] FROM [datatypes]").first['count']
      assert count > 10, 'since we want to cancel early for test'
      result = @client.execute("SELECT [id] FROM [datatypes]")
      index = 0
      result.each do |row|
        break if index > 10
        index += 1
      end
      
      _(@client.sqlsent?).must_equal false
      _(@client.canceled?).must_equal true
    end

    it 'allows #return_code to work with stored procedures and reset per sql batch' do
      assert_nil @client.return_code

      result = @client.execute("EXEC tinytds_TestReturnCodes")
      assert_equal [{ "one" => 1 }], result.rows
      assert_equal 420, @client.return_code
      assert_equal 420, result.return_code

      result = @client.execute('SELECT 1 as [one]')
      assert_nil @client.return_code
      assert_nil result.return_code
    end

    it 'with LOGINPROPERTY function' do
      v = @client.execute("SELECT LOGINPROPERTY('sa', 'IsLocked') as v").first['v']
      _(v).must_equal 0
    end

    describe 'with multiple result sets' do

      before do
        @empty_select = "SELECT 1 AS [rs1] WHERE 1 = 0"
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

      it 'handles a command buffer with double selects' do
        result = @client.execute(@double_select)
        assert_equal 2, result.count
        assert_equal [{ 'rs1' => 1 }], result.rows.first
        assert_equal [{ 'rs2' => 2 }], result.rows.last
        assert_equal [['rs1'], ['rs2']], result.fields
        
        # As array
        result = @client.execute(@double_select, as: :array)
        assert_equal 2, result.count
        assert_equal [[1]], result.rows.first
        assert_equal [[2]], result.rows.last
        assert_equal [['rs1'], ['rs2']], result.fields
      end

      it 'yields each row for each result set' do
        data = []

        result = @client.execute(@double_select)
        result.each { |row| data << row }

        assert_equal data.first, result.rows.first
        assert_equal data.last, result.rows.last
      end

      it 'works from a stored procedure' do
        results1, results2 = @client.execute("EXEC sp_helpconstraint '[datatypes]'").rows
        assert_equal [{ "Object Name" => "[datatypes]" }], results1
        constraint_info = results2.first
        assert constraint_info.key?("constraint_keys")
        assert constraint_info.key?("constraint_type")
        assert constraint_info.key?("constraint_name")
      end

      describe 'using :empty_sets TRUE' do

        before do
          close_client
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = true
          @client = new_connection
        end

        after do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end

        it 'handles a basic empty result set' do
          result = @client.execute(@empty_select)
          assert_equal [], result.to_a
          assert_equal ['rs1'], result.fields
        end

        it 'includes empty result sets by default - using 1st empty buffer' do
          result = @client.execute(@triple_select_1st_empty)
          assert_equal 3, result.count
          assert_equal [], result.rows[0]
          assert_equal [{ 'rs2' => 2 }], result.rows[1]
          assert_equal [{ 'rs3' => 3 }], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields

          # As array
          result = @client.execute(@triple_select_1st_empty, as: :array)
          assert_equal 3, result.count
          assert_equal [], result.rows[0]
          assert_equal [[2]], result.rows[1]
          assert_equal [[3]], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
        end

        it 'includes empty result sets by default - using 2nd empty buffer' do
          result = @client.execute(@triple_select_2nd_empty)
          assert_equal 3, result.count
          assert_equal [{ 'rs1' => 1 }], result.rows[0]
          assert_equal [], result.rows[1]
          assert_equal [{ 'rs3' => 3 }], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields

          # As array
          result = @client.execute(@triple_select_2nd_empty, as: :array)
          assert_equal 3, result.count
          assert_equal [[1]], result.rows[0]
          assert_equal [], result.rows[1]
          assert_equal [[3]], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
        end

        it 'includes empty result sets by default - using 3rd empty buffer' do
          result = @client.execute(@triple_select_3rd_empty)
          assert_equal 3, result.count
          assert_equal [{ 'rs1' => 1 }], result.rows[0]
          assert_equal [{ 'rs2' => 2 }], result.rows[1]
          assert_equal [], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
          
          # As array
          result = @client.execute(@triple_select_3rd_empty, as: :array)
          assert_equal 3, result.count
          assert_equal [[1]], result.rows[0]
          assert_equal [[2]], result.rows[1]
          assert_equal [], result.rows[2]
          assert_equal [['rs1'], ['rs2'], ['rs3']], result.fields
        end

      end

      describe 'using :empty_sets FALSE' do
        before do
          close_client
          @old_query_option_value = TinyTds::Client.default_query_options[:empty_sets]
          TinyTds::Client.default_query_options[:empty_sets] = false
          @client = new_connection
        end

        after do
          TinyTds::Client.default_query_options[:empty_sets] = @old_query_option_value
        end

        it 'handles a basic empty result set' do
          result = @client.execute(@empty_select)
          assert_equal [], result.rows
          assert_equal ['rs1'], result.fields
        end

        it 'must not include empty result sets by default - using 1st empty buffer' do
          result = @client.execute(@triple_select_1st_empty)
          assert_equal 2, result.count
          assert_equal [{ 'rs2' => 2 }], result.rows[0]
          assert_equal [{ 'rs3' => 3 }], result.rows[1]
          assert_equal [['rs2'], ['rs3']], result.fields
          
          # As array
          result = @client.execute(@triple_select_1st_empty, as: :array)
          assert_equal 2, result.count
          assert_equal [[2]], result.rows[0]
          assert_equal [[3]], result.rows[1]
          assert_equal [['rs2'], ['rs3']], result.fields
        end

        it 'must not include empty result sets by default - using 2nd empty buffer' do
          result = @client.execute(@triple_select_2nd_empty)
          assert_equal 2, result.count
          assert_equal [{ 'rs1' => 1 }], result.rows[0]
          assert_equal [{ 'rs3' => 3 }], result.rows[1]
          assert_equal [['rs1'], ['rs3']], result.fields
          
          # As array
          result = @client.execute(@triple_select_2nd_empty, as: :array)
          assert_equal 2, result.count
          assert_equal [[1]], result.rows[0]
          assert_equal [[3]], result.rows[1]
          assert_equal [['rs1'], ['rs3']], result.fields
        end

        it 'must not include empty result sets by default - using 3rd empty buffer' do
          result = @client.execute(@triple_select_3rd_empty)
          assert_equal 2, result.count
          assert_equal [{ 'rs1' => 1 }], result.rows[0]
          assert_equal [{ 'rs2' => 2 }], result.rows[1]
          assert_equal [['rs1'], ['rs2']], result.fields

          # As array
          result = @client.execute(@triple_select_3rd_empty, as: :array)
          assert_equal 2, result.count
          assert_equal [[1]], result.rows[0]
          assert_equal [[2]], result.rows[1]
          assert_equal [['rs1'], ['rs2']], result.fields
        end
      end
    end

    describe 'Complex query with multiple results sets but no actual results' do

      let(:backup_file) { 'C:\\Users\\Public\\tinytdstest.bak' }

      after { File.delete(backup_file) if File.exist?(backup_file) }

      it 'must not cancel the query until complete' do
        @client.do("BACKUP DATABASE tinytdstest TO DISK = '#{backup_file}'")
      end

    end unless sqlserver_azure?

    describe 'when casting to native ruby values' do

      it 'returns fixnum for 1' do
        value = @client.execute('SELECT 1 AS [fixnum]').each.first['fixnum']
        assert_equal 1, value
      end

      it 'returns nil for NULL' do
        value = @client.execute('SELECT NULL AS [null]').each.first['null']
        assert_nil value
      end

    end

    describe 'with data type' do

      describe 'char max' do

        before do
          @big_text = 'x' * 2_000_000
          @old_textsize = @client.execute("SELECT @@TEXTSIZE AS [textsize]").each.first['textsize'].inspect
          @client.do("SET TEXTSIZE #{(@big_text.length * 2) + 1}")
        end

        it 'must insert and select large varchar_max' do
          insert_and_select_datatype :varchar_max
        end

        it 'must insert and select large nvarchar_max' do
          insert_and_select_datatype :nvarchar_max
        end

      end

    end

    describe 'when shit happens' do

      it 'copes with nil or empty buffer' do
        assert_raises(TypeError) { @client.execute(nil) }
        assert_equal [], @client.execute('').rows
      end

      describe 'using :message_handler option' do
        let(:messages) { Array.new }

        before do
          close_client
          @client = new_connection message_handler: Proc.new { |m| messages << m }
        end

        after do
          messages.clear
        end

        it 'has a message handler that responds to call' do
          assert @client.message_handler.respond_to?(:call)
        end

        it 'calls the provided message handler when severity is 10 or less' do
          (1..10).to_a.each do |severity|
            messages.clear
            msg = "Test #{severity} severity"
            state = rand(1..255)
            @client.do("RAISERROR(N'#{msg}', #{severity}, #{state})")
            m = messages.first
            assert_equal 1, messages.length, 'there should be one message after one raiserror'
            assert_equal msg, m.message, 'message text'
            assert_equal severity, m.severity, 'message severity' unless severity == 10 && m.severity.to_i == 0
            assert_equal state, m.os_error_number, 'message state'
          end
        end

        it 'calls the provided message handler for `print` messages' do
          messages.clear
          msg = 'hello'
          @client.do("PRINT '#{msg}'")
          m = messages.first
          assert_equal 1, messages.length, 'there should be one message after one print statement'
          assert_equal msg, m.message, 'message text'
        end

        it 'must raise an error preceded by a `print` message' do
          messages.clear
          action = lambda { @client.do("EXEC tinytds_TestPrintWithError") }
          assert_raise_tinytds_error(action) do |e|
            assert_equal 'hello', messages.first.message, 'message text'

            assert_equal "Error following print", e.message
            assert_equal 16, e.severity
            assert_equal 50000, e.db_error_number
          end
        end

        it 'calls the provided message handler for each of a series of `print` messages' do
          messages.clear
          @client.do("EXEC tinytds_TestSeveralPrints")
          assert_equal ['hello 1', 'hello 2', 'hello 3'], messages.map { |e| e.message }, 'message list'
        end

        it 'should flush info messages before raising error in cases of timeout' do
          @client = new_connection timeout: 1, message_handler: Proc.new { |m| messages << m }
          action = lambda { @client.do("print 'hello'; waitfor delay '00:00:02'") }
          messages.clear
          assert_raise_tinytds_error(action) do |e|
            assert_match %r{timed out}i, e.message, 'ignore if non-english test run'
            assert_equal 6, e.severity
            assert_equal 20003, e.db_error_number
            assert_equal 'hello', messages.first&.message, 'message text'
          end
        end

        it 'should print info messages before raising error in cases of timeout' do
          @client = new_connection timeout: 1, message_handler: Proc.new { |m| messages << m }
          action = lambda { @client.do("raiserror('hello', 1, 1) with nowait; waitfor delay '00:00:02'") }
          messages.clear
          assert_raise_tinytds_error(action) do |e|
            assert_match %r{timed out}i, e.message, 'ignore if non-english test run'
            assert_equal 6, e.severity
            assert_equal 20003, e.db_error_number
            assert_equal 'hello', messages.first&.message, 'message text'
          end
        end
      end

      it 'must not raise an error when severity is 10 or less' do
        (1..10).to_a.each do |severity|
          @client.do("RAISERROR(N'Test #{severity} severity', #{severity}, 1)")
        end
      end

      it 'raises an error when severity is greater than 10' do
        action = lambda { @client.do("RAISERROR(N'Test 11 severity', 11, 1)") }
        assert_raise_tinytds_error(action) do |e|
          assert_equal "Test 11 severity", e.message
          assert_equal 11, e.severity
          assert_equal 50000, e.db_error_number
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
      @client.do("DELETE FROM [datatypes] WHERE [#{datatype}] IS NOT NULL")
      id = @client.insert("INSERT INTO [datatypes] ([#{datatype}]) VALUES (N'#{@big_text}')")
      found_text = find_value id, datatype
      flunk "Large #{datatype} data with a length of #{@big_text.length} did not match found text with length of #{found_text.length}" unless @big_text == found_text
    end
  end

end
