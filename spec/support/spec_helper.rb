
require 'simplecov'
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'

ENV["RAILS_ENV"] ||= 'development'
require File.expand_path("../../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'

require 'active_model'
require 'mongoid'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
#Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
   # == Mock Framework
   # config.mock_with :mocha
   
   # == Includes

   # Since this app doesn't use ActiveRecord
   #config.use_transactional_fixtures = false
   
  config.before :each do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
