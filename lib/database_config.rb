require 'mongoid'
require_relative 'simple_logging'

require_relative 'application_defs'

ENV["RACK_ENV"] = ENV.fetch("RACK_ENV", "development")
RAILS_ROOT = File.expand_path("../../", __FILE__)
Mongoid.logger = Logger.from_file_name(File.join(ApplicationDefs::LOG_DIRECTORY, 'mongoid.log'))
Moped.logger = Logger.from_file_name(File.join(ApplicationDefs::LOG_DIRECTORY, 'moped.log'))
Mongoid.load!("#{RAILS_ROOT}/config/mongoid.yml")