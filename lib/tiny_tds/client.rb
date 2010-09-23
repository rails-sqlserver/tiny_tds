module TinyTds
  class Client
    
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
      host     = opts[:host] || 'localhost'
      user     = opts[:username]
      pass     = opts[:password]
      database = opts[:database]
      connect
    end

    
  end
end
