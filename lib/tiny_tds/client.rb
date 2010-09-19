module TinyTds
  class Client
    
    attr_reader :query_options
    
    @@default_query_options = {
      :as => :hash,
      :symbolize_keys => false,
      :database_timezone => :local,
      :application_timezone => nil,
      :cache_rows => true
    }
    
    def self.default_query_options
      @@default_query_options
    end

    def initialize(opts={})
      @query_options = @@default_query_options.dup
      init_connection
      user     = opts[:username]
      pass     = opts[:password]
      host     = opts[:host] || 'localhost'
      port     = opts[:port] || 3306
      database = opts[:database]
      connect(user, pass, host, port, database)
    end

    
  end
end
