# encoding: UTF-8
require 'date'
require 'bigdecimal'
require 'rational' unless RUBY_VERSION >= '1.9.2'

require 'tiny_tds/error'
require 'tiny_tds/client'
require 'tiny_tds/result'

# support multiple ruby version (fat binaries under windows)
begin
  RUBY_VERSION =~ /(\d+.\d+)/
  require "tiny_tds/#{$1}/tiny_tds"
rescue LoadError
  require 'tiny_tds/tiny_tds'
end

# = TinyTds
#
# Tiny Ruby Wrapper For FreeTDS Using DB-Library
module TinyTds
  VERSION = '0.4.3'
end
