require_relative '../../lib/application_defs'
require_relative '../../bots/bots'
require_relative '../../app/workers/table_manager/table_manager'
require_relative '../../app/workers/table_manager_worker'
require 'awesome_print'
require 'sidekiq'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add TableManager::Factory.new
  end
end
# Want to instantiate one worker upon starting
TableManager::Worker.perform_async('maintain') if Sidekiq.server?
