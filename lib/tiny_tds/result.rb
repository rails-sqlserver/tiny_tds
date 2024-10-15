module TinyTds
  class Result
    attr_reader :affected_rows, :fields, :rows, :return_code

    include Enumerable

    def each(&bk)
      rows.each(&bk)
    end
  end
end
