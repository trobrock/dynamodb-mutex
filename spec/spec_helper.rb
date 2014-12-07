require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'fake_dynamo'
require 'aws-sdk'

AWS.config(:use_ssl => false,
           :dynamo_db_endpoint => 'localhost',
           :dynamo_db_port => 4567)

require 'dynamodb-mutex'

RSpec.configure do |config|

  dynamo_thread = nil

  config.before(:suite) do
    FakeDynamo::Storage.db_path = 'test.fdb'
    FakeDynamo::Storage.instance.load_aof

    dynamo_thread = Thread.new do
      FakeDynamo::Server.run!(port: 4567, bind: 'localhost') do |server|
        if server.respond_to?('config') && server.config.respond_to?('[]=')
          server.config[:AccessLog] = []
        end
      end
    end
    sleep(1)
  end

  config.after(:suite) do
    FakeDynamo::Storage.instance.shutdown
    dynamo_thread.exit if dynamo_thread
    FileUtils.rm('test.fdb', force: true)
  end

end