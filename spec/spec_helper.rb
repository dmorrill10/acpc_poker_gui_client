# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'models_helper'
require 'game_definition_helper'
require 'matchstate_string_helper'
require File.expand_path('../support/model_test_helper', __FILE__)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
   # == Mock Framework
   config.mock_with :mocha
   
   # == Includes
   config.include ModelsHelper
   config.include GameDefinitionHelper
   config.include MatchstateStringHelper
   config.include ModelTestHelper

   # Since this app doesn't use ActiveRecord
   #config.use_transactional_fixtures = false
end
