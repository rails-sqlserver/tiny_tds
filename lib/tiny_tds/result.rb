module TinyTds
  class Result
    
    include Enumerable
    
    def first
      each(first: true).first
    end
  end
end
