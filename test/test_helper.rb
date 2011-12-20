# encoding: UTF-8
require 'rubygems'
require 'bundler'
Bundler.setup
require 'tiny_tds'
require 'mini_shoulda'
require 'minitest/autorun'

class DateTime
  def usec
    if RUBY_VERSION >= '1.9'
      (sec_fraction * 1_000_000).to_i
    else
      (sec_fraction * 60 * 60 * 24 * (10**6)).to_i
    end
  end
end

TINYTDS_SCHEMAS = ['sqlserver_2000', 'sqlserver_2005', 'sqlserver_2008', 'sqlserver_azure', 'sybase_ase'].freeze

module TinyTds
  class TestCase < MiniTest::Spec
    
    class << self
      
      def current_schema
        ENV['TINYTDS_SCHEMA'] || 'sqlserver_2008'
      end
      
      TINYTDS_SCHEMAS.each do |schema|
        define_method "#{schema}?" do
          schema == self.current_schema
        end
      end
      
    end
    
    
    protected
    
    TINYTDS_SCHEMAS.each do |schema|
      define_method "#{schema}?" do
        schema == self.class.current_schema
      end
    end
    
    def current_schema
      self.class.current_schema
    end
    
    def new_connection(options={})
      client = TinyTds::Client.new(connection_options(options))
      if sybase_ase?
        client.execute("SET ANSINULL ON").do
      elsif !sqlserver_azure?
        client.execute("SET ANSI_DEFAULTS ON").do
        client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
        client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
      end
      client
    end
    
    def connection_options(options={})
      username = sqlserver_azure? ? ENV['TINYTDS_UNIT_AZURE_USER'] : ENV['TINYTDS_UNIT_USER'] || 'tinytds'
      password = sqlserver_azure? ? ENV['TINYTDS_UNIT_AZURE_PASS'] : ENV['TINYTDS_UNIT_PASS'] || ''
      { :dataserver    => ENV['TINYTDS_UNIT_DATASERVER'],
        :host          => ENV['TINYTDS_UNIT_HOST'],
        :port          => ENV['TINYTDS_UNIT_PORT'],
        :username      => username,
        :password      => password,
        :database      => 'tinytdstest',
        :appname       => 'TinyTds Dev',
        :login_timeout => 5,
        :timeout       => 5,
        :azure         => sqlserver_azure?
      }.merge(options)
    end
    
    def assert_client_works(client)
      client.execute("SELECT 'client_works' as [client_works]").each
    end
    
    def assert_new_connections_work
      client = new_connection
      client.execute("SELECT 'new_connections_work' as [new_connections_work]").each
    end
    
    def assert_raise_tinytds_error(action)
      error_raised = false
      begin
        action.call
      rescue TinyTds::Error => e
        error_raised = true
      end
      assert error_raised, 'expected a TinyTds::Error but none happened'
      yield e
    end
    
    def inspect_tinytds_exception
      begin
        yield
      rescue TinyTds::Error => e
        props = { :source => e.source, :message => e.message, :severity => e.severity, 
                  :db_error_number => e.db_error_number, :os_error_number => e.os_error_number }
        raise "TinyTds::Error - #{props.inspect}"
      end
    end
    
    def assert_binary_encoding(value)
      assert_equal Encoding.find('BINARY'), value.encoding if ruby19?
    end
    
    def assert_utf8_encoding(value)
      assert_equal Encoding.find('UTF-8'), value.encoding if ruby19?
    end
    
    def ruby18?
      RUBY_VERSION < '1.9'
    end
    
    def ruby186?
      RUBY_VERSION == '1.8.6'
    end
    
    def ruby19?
      RUBY_VERSION >= '1.9'
    end
    
    def ruby192?
      RUBY_VERSION == '1.9.2'
    end
    
    def ruby32bit?
      1.size == 4
    end
    
    def rubyRbx?
      RUBY_DESCRIPTION =~ /rubinius/i
    end
    
    def load_current_schema
      loader = new_connection
      schema_file = File.expand_path File.join(File.dirname(__FILE__), 'schema', "#{current_schema}.sql")
      schema_sql = ruby18? ? File.read(schema_file) : File.open(schema_file,"rb:UTF-8") { |f|f.read }

      loader.execute(drop_sql).each
      loader.execute(schema_sql).cancel
      loader.execute(sp_sql).cancel
      loader.close
      true
    end

    def drop_sql
      sybase_ase? ? drop_sql_sybase : drop_sql_microsoft
    end

    def drop_sql_sybase
      %|IF EXISTS(
          SELECT 1 FROM sysobjects WHERE type = 'U' AND name = 'datatypes'
        ) DROP TABLE datatypes
        IF EXISTS(
          SELECT 1 FROM sysobjects WHERE type = 'P' AND name = 'tinytds_TestReturnCodes'
        ) DROP PROCEDURE tinytds_TestReturnCodes|
    end

    def drop_sql_microsoft
      %|IF EXISTS (
          SELECT TABLE_NAME
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_CATALOG = 'tinytdstest' 
          AND TABLE_TYPE = 'BASE TABLE' 
          AND TABLE_NAME = 'datatypes'
        ) DROP TABLE [datatypes]
        IF EXISTS (
          SELECT name FROM sysobjects 
          WHERE name = 'tinytds_TestReturnCodes' AND type = 'P'
        ) DROP PROCEDURE tinytds_TestReturnCodes|
    end
    
    def sp_sql
      %|CREATE PROCEDURE tinytds_TestReturnCodes
        AS
        SELECT 1 as [one]
        RETURN(420) |
    end

    def find_value(id, column, query_options={})
      query_options[:timezone] ||= :utc
      sql = "SELECT [#{column}] FROM [datatypes] WHERE [id] = #{id}"
      @client.execute(sql).each(query_options).first[column.to_s]
    end
    
    def local_offset
      TinyTds::Client.local_offset
    end
    
    def utc_offset
      ::Time.local(2010).utc_offset
    end
    
    def rollback_transaction(client)
      client.execute("BEGIN TRANSACTION").do
      yield
    ensure
      client.execute("ROLLBACK TRANSACTION").do
    end
    
    
  end
end

