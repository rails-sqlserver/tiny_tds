module TinyTds  
  class Error < StandardError
    
    SEVERITIES = [
      {:number => 1,   :severity => 'EXINFO',         :explanation => 'Informational, non-error.'},
      {:number => 2,   :severity => 'EXUSER',         :explanation => 'User error.'},
      {:number => 3,   :severity => 'EXNONFATAL',     :explanation => 'Non-fatal error.'},
      {:number => 4,   :severity => 'EXCONVERSION',   :explanation => 'Error in DB-Library data conversion.'},
      {:number => 5,   :severity => 'EXSERVER',       :explanation => 'The Server has returned an error flag.'},
      {:number => 6,   :severity => 'EXTIME',         :explanation => 'We have exceeded our timeout period while waiting for a response from the Server - the DBPROCESS is still alive.'},
      {:number => 7,   :severity => 'EXPROGRAM',      :explanation => 'Coding error in user program.'},
      {:number => 8,   :severity => 'EXRESOURCE',     :explanation => 'Running out of resources - the DBPROCESS may be dead.'},
      {:number => 9,   :severity => 'EXCOMM',         :explanation => 'Failure in communication with Server - the DBPROCESS is dead.'},
      {:number => 10,  :severity => 'EXFATAL',        :explanation => 'Fatal error - the DBPROCESS is dead.'},
      {:number => 11,  :severity => 'EXCONSISTENCY',  :explanation => 'Internal software error - notify Sybase Technical Support.'}
    ].freeze
    
    attr_accessor :source, :severity, :db_error_number, :os_error_number
    
    def initialize(message)
      super
      @severity = nil
      @db_error_number = nil
      @os_error_number = nil
    end


  end
end
