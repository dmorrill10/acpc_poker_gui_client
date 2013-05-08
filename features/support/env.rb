ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) << '/../../config/environment')

require 'cucumber/formatter/unicode'
require 'cucumber/rails/rspec'
require 'cucumber/rails/world'
require 'cucumber/web/tableish'

require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'cucumber/rails/capybara_javascript_emulation'

Capybara.default_selector = :css

ActionController::Base.allow_rescue = false

require 'factory_girl'
require 'factory_girl/step_definitions'
Dir[File.expand_path(File.join(File.dirname(__FILE__),'..','..',
  'spec','factories','*.rb'))].each {|f| require f}
