# encoding: UTF-8
require 'date'
require 'bigdecimal'
require 'rational' unless RUBY_VERSION >= '1.9.2'

require 'tiny_tds/version'
require 'tiny_tds/error'
require 'tiny_tds/client'
require 'tiny_tds/result'

# Support multiple ruby versions, fat binaries under Windows.
begin
  RUBY_VERSION =~ /(\d+.\d+)/
  require "tiny_tds/#{$1}/tiny_tds"
rescue LoadError
  require 'tiny_tds/tiny_tds'
end


