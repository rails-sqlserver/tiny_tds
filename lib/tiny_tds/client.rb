module TinyTds
  class Client
    
    TDS_VERSIONS_SETTERS = {
      'unknown' => 0,
      '46'      => 1,
      '100'     => 2,
      '42'      => 3,
      '70'      => 4,
      '80'      => 5,
      '90'      => 6  # TODO: untested
    }.freeze
    
    TDS_VERSIONS_GETTERS = {
      0  => {:name => 'DBTDS_UNKNOWN', :description => 'Unknown'},
      1  => {:name => 'DBTDS_2_0',     :description => 'Pre 4.0 SQL Server'},
      2  => {:name => 'DBTDS_3_4',     :description => 'Microsoft SQL Server (3.0)'},
      3  => {:name => 'DBTDS_4_0',     :description => '4.0 SQL Server'},
      4  => {:name => 'DBTDS_4_2',     :description => '4.2 SQL Server'},
      5  => {:name => 'DBTDS_4_6',     :description => '2.0 OpenServer and 4.6 SQL Server.'},
      6  => {:name => 'DBTDS_4_9_5',   :description => '4.9.5 (NCR) SQL Server'},
      7  => {:name => 'DBTDS_5_0',     :description => '5.0 SQL Server'},
      8  => {:name => 'DBTDS_7_0',     :description => 'Microsoft SQL Server 7.0'},
      9  => {:name => 'DBTDS_8_0',     :description => 'Microsoft SQL Server 2000'},
      10 => {:name => 'DBTDS_9_0',     :description => 'Microsoft SQL Server 2005'}
    }.freeze
    
    @@default_query_options = {
      :as => :hash,
      :symbolize_keys => false,
      :database_timezone => :local,
      :application_timezone => nil
    }
    
    attr_reader :query_options
    
    
    def self.default_query_options
      @@default_query_options
    end


    def initialize(opts={})
      @query_options = @@default_query_options.dup
      user     = opts[:username]
      pass     = opts[:password]
      host     = opts[:host] || 'localhost'
      database = opts[:database]
      appname  = opts[:appname] || 'TinyTds'
      version  = TDS_VERSIONS_SETTERS[opts[:tds_version].to_s] || TDS_VERSIONS_SETTERS['80']
      ltimeout = opts[:login_timeout] || 60
      timeout  = opts[:timeout]
      encoding = (opts[:encoding].nil? || opts[:encoding].downcase == 'utf8') ? 'UTF-8' : opts[:encoding]
      raise ArgumentError, 'missing :username option' if user.nil? || user.empty?
      connect(user, pass, host, database, appname, version, ltimeout, timeout, encoding)
    end
    
    def tds_version_info
      info = TDS_VERSIONS_GETTERS[tds_version]
      "#{info[:name]} - #{info[:description]}" if info
    end


    private
    
    def self.local_offset
      ::Time.local(2010).utc_offset.to_r / 86400
    end
    
  end
end
