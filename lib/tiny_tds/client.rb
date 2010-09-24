module TinyTds
  class Client
    
    TDS_VERSIONS = {
      'unknown' => 0,
      '46'      => 1,
      '100'     => 2,
      '42'      => 3,
      '70'      => 4,
      '80'      => 5
    }.freeze
    
    attr_reader :query_options
    
    @@default_query_options = {
      :as => :hash,
      :symbolize_keys => false,
      :database_timezone => :local,
      :application_timezone => nil
    }
    
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
      version  = TDS_VERSIONS[opts[:tds_version].to_s] || TDS_VERSIONS['80']
      raise ArgumentError, 'missing :username option' if user.nil? || user.empty?
      connect(user, pass, host, database, appname, version)
    end

    
  end
end
