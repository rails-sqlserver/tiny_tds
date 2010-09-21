require 'test_helper'

class BuildTest < TinyTds::TestCase
  
  def setup
    @client = TinyTds::Client.new
    @result = TinyTds::Result.new
  end
  
  context 'The client' do

    should 'respond true to a test stub' do
      assert @client.test
    end

  end
  
  context 'The result' do

    should 'respond true to a test stub' do
      assert @result.test
    end

  end
  
  
  
end

