require 'tiny_tds'

setupsql = File.read File.expand_path('../setup.sql', __FILE__)
password = ENV['TINYTDS_UNIT_SA_PASSWORD'] || 'super01S3cUr3'

client = TinyTds::Client.new username: 'sa', password: password, host: 'localhost'
client.execute(setupsql).do
client.close
