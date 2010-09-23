require 'test/unit'
require 'rubygems'
require 'bundler'
Bundler.setup
require 'shoulda'
require 'mocha'
require 'tiny_tds'

module TinyTds 
  class TestCase < Test::Unit::TestCase
    
    def test_base_tiny_tds_case ; assert(true) ; end
    
    
    protected
    
    def connection_options(options={})
      { :username => 'tinytds',
        :password => '',
        :database => 'tinytds_test'
      }.merge(options)
    end
    
  end
end

