module TinyTds
  class Client

    # From sybdb.h comments:
    # DBVERSION_xxx are used with dbsetversion()
    #
    TDS_VERSIONS_SETTERS = {
      'unknown' => 0,
      '46'      => 1,
      '100'     => 2,
      '42'      => 3,
      '70'      => 4,
      '71'      => 5,
      '80'      => 5,
      '72'      => 6,
      '90'      => 6
    }.freeze

    # From sybdb.h comments:
    # DBTDS_xxx are returned by DBTDS()
    # The integer values of the constants are poorly chosen.
    #
    TDS_VERSIONS_GETTERS = {
      0  => {:name => 'DBTDS_UNKNOWN',        :description => 'Unknown'},
      1  => {:name => 'DBTDS_2_0',            :description => 'Pre 4.0 SQL Server'},
      2  => {:name => 'DBTDS_3_4',            :description => 'Microsoft SQL Server (3.0)'},
      3  => {:name => 'DBTDS_4_0',            :description => '4.0 SQL Server'},
      4  => {:name => 'DBTDS_4_2',            :description => '4.2 SQL Server'},
      5  => {:name => 'DBTDS_4_6',            :description => '2.0 OpenServer and 4.6 SQL Server.'},
      6  => {:name => 'DBTDS_4_9_5',          :description => '4.9.5 (NCR) SQL Server'},
      7  => {:name => 'DBTDS_5_0',            :description => '5.0 SQL Server'},
      8  => {:name => 'DBTDS_7_0',            :description => 'Microsoft SQL Server 7.0'},
      9  => {:name => 'DBTDS_7_1/DBTDS_8_0',  :description => 'Microsoft SQL Server 2000'},
      10 => {:name => 'DBTDS_7_2/DBTDS_9_0',  :description => 'Microsoft SQL Server 2005'}
    }.freeze

    @@default_query_options = {
      :as => :hash,
      :symbolize_keys => false,
      :cache_rows => true,
      :timezone => :local,
      :empty_sets => true
    }

    attr_reader :query_options

    class << self

      def default_query_options
        @@default_query_options
      end

      # Most, if not all, iconv encoding names can be found by ruby. Just in case, you can
      # overide this method to return a string name that Encoding.find would work with. Default
      # is to return the passed encoding.
      def transpose_iconv_encoding(encoding)
        encoding
      end

    end


    def initialize(opts={})
      raise ArgumentError, 'missing :host option if no :dataserver given' if opts[:dataserver].to_s.empty? && opts[:host].to_s.empty?
      @query_options = @@default_query_options.dup
      opts[:password] = opts[:password].to_s if opts[:password] && opts[:password].to_s.strip != ''
      opts[:appname] ||= 'TinyTds'
      opts[:tds_version] = TDS_VERSIONS_SETTERS[opts[:tds_version].to_s] || TDS_VERSIONS_SETTERS['71']
      opts[:login_timeout] ||= 60
      opts[:timeout] ||= 5
      opts[:encoding] = (opts[:encoding].nil? || opts[:encoding].downcase == 'utf8') ? 'UTF-8' : opts[:encoding].upcase
      opts[:port] ||= 1433
      opts[:dataserver] = "#{opts[:host]}:#{opts[:port]}" if opts[:dataserver].to_s.empty?
      connect(opts)
    end

    def tds_version_info
      info = TDS_VERSIONS_GETTERS[tds_version]
      "#{info[:name]} - #{info[:description]}" if info
    end

    def active?
      !closed? && !dead?
    end


    private

    def self.local_offset
      ::Time.local(2010).utc_offset.to_r / 86400
    end

  end
end
