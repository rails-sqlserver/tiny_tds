module TinyTds
  class Client
    attr_reader :app_name, :charset, :contained, :database, :dataserver, :message_handler, :login_timeout, :password, :port, :tds_version, :timeout, :username, :use_utf16

    @default_query_options = {
      as: :hash,
      empty_sets: true,
      timezone: :local
    }

    attr_reader :query_options

    class << self
      attr_reader :default_query_options

      def local_offset
        ::Time.local(2010).utc_offset.to_r / 86_400
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def initialize(app_name: "TinyTds", azure: false, charset: "UTF-8", contained: false, database: nil, dataserver: nil, message_handler: nil, host: nil, login_timeout: 60, password: nil, port: 1433, tds_version: nil, timeout: 5, username: nil, use_utf16: true)
      if dataserver.to_s.empty? && host.to_s.empty?
        raise ArgumentError, "missing :host option if no :dataserver given"
      end

      if message_handler && !message_handler.respond_to?(:call)
        raise ArgumentError, ":message_handler must implement `call` (eg, a Proc or a Method)"
      else
        @message_handler = message_handler
      end

      @app_name = app_name
      @charset = (charset.nil? || charset.casecmp("utf8").zero?) ? "UTF-8" : charset.upcase
      @database = database
      @dataserver = dataserver || "#{host}:#{port}"
      @login_timeout = login_timeout.to_i
      @password = password if password && password.to_s.strip != ""
      @port = port.to_i
      @timeout = timeout.to_i
      @tds_version = tds_versions_setter(tds_version:)
      @username = parse_username(azure:, host:, username:)
      @use_utf16 = use_utf16.nil? || ["true", "1", "yes"].include?(use_utf16.to_s)
    end

    def tds_73?
      server_version >= 11
    end

    def server_version_info
      info = TDS_VERSIONS_GETTERS[server_version]
      "#{info[:name]} - #{info[:description]}" if info
    end

    def active?
      !closed? && !dead?
    end

    private

    def parse_username(username:, azure: false, host: nil)
      return username if username.nil? || !azure
      return username if username.include?("@") && !username.include?("database.windows.net")
      user, domain = username.split("@")
      domain ||= host
      "#{user}@#{domain.split(".").first}"
    end

    def tds_versions_setter(tds_version:)
      v = tds_version || ENV["TDSVER"] || "7.3"
      TDS_VERSIONS_SETTERS[v.to_s]
    end

    # From sybdb.h comments:
    # DBVERSION_xxx are used with dbsetversion()
    #
    TDS_VERSIONS_SETTERS = {
      "unknown" => 0,
      "46" => 1,
      "100" => 2,
      "42" => 3,
      "70" => 4,
      "7.0" => 4,
      "71" => 5,
      "7.1" => 5,
      "80" => 5,
      "8.0" => 5,
      "72" => 6,
      "7.2" => 6,
      "90" => 6,
      "9.0" => 6,
      "73" => 7,
      "7.3" => 7
    }.freeze

    # From sybdb.h comments:
    # DBTDS_xxx are returned by DBTDS()
    # The integer values of the constants are poorly chosen.
    #
    TDS_VERSIONS_GETTERS = {
      0 => {name: "DBTDS_UNKNOWN", description: "Unknown"},
      1 => {name: "DBTDS_2_0", description: "Pre 4.0 SQL Server"},
      2 => {name: "DBTDS_3_4", description: "Microsoft SQL Server (3.0)"},
      3 => {name: "DBTDS_4_0", description: "4.0 SQL Server"},
      4 => {name: "DBTDS_4_2", description: "4.2 SQL Server"},
      5 => {name: "DBTDS_4_6", description: "2.0 OpenServer and 4.6 SQL Server."},
      6 => {name: "DBTDS_4_9_5", description: "4.9.5 (NCR) SQL Server"},
      7 => {name: "DBTDS_5_0", description: "5.0 SQL Server"},
      8 => {name: "DBTDS_7_0", description: "Microsoft SQL Server 7.0"},
      9 => {name: "DBTDS_7_1/DBTDS_8_0", description: "Microsoft SQL Server 2000"},
      10 => {name: "DBTDS_7_2/DBTDS_9_0", description: "Microsoft SQL Server 2005"},
      11 => {name: "DBTDS_7_3", description: "Microsoft SQL Server 2008"},
      12 => {name: "DBTDS_7_4", description: "Microsoft SQL Server 2012/2014"}
    }.freeze
  end
end
