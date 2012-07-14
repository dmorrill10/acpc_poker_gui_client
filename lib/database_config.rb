require 'mongoid'
ENV["RACK_ENV"] = ENV.fetch("RACK_ENV", "development")
RAILS_ROOT = File.expand_path("../../", __FILE__)
Mongoid.logger = nil
Mongoid.load!("#{RAILS_ROOT}/config/mongoid.yml")
