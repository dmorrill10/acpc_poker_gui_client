#!/usr/bin/env ruby

require 'acpc_backend'
require 'redis'
require 'json'

require "awesome_print"

if __FILE__ == $0
  APP_ENV_LABEL = if ARGV.empty? then 'default' else ARGV.first end

  ROOT = File.expand_path('../../', __FILE__)
  REDIS_CONFIG = YAML.load(File.open(File.join(ROOT, 'config', 'redis.yml'))).symbolize_keys
  DFLT = REDIS_CONFIG[:default].symbolize_keys
  CNFG = if REDIS_CONFIG[APP_ENV_LABEL.to_sym]
    DFLT.merge(REDIS_CONFIG[APP_ENV_LABEL.to_sym].symbolize_keys)
  else
    DFLT
  end

  redis = Redis.new(CNFG)

  CONFIG_FILE = File.join(ROOT, 'config', 'acpc_backend.yml')

  AcpcBackend.load! CONFIG_FILE
  table_manager = AcpcBackend::TableManager.new
  loop do
    message = redis.blpop("backend", :timeout => AcpcBackend.config.maintenance_interval_s)
    if message
      ap({acpc_backend_client: true, message_received: message})
      data = JSON.parse message[1]
      if data['request'] == 'reload'
        AcpcBackend.load! CONFIG_FILE
      else
        table_manager.perform! data['request'], data['params']
      end
    else
      table_manager.maintain!
    end
  end
end
