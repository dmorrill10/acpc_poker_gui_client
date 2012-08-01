source 'http://rubygems.org'

gem 'rails', '3.2.6'

gem 'rack', '1.4.1'

# Database module
gem "mongoid"
gem 'bson'
gem 'bson_ext'

# For convenient styling macros and SASS
gem 'compass'
gem 'compass-rails'

# To interpret Coffeescript in HAML
gem 'coffee-filter'

# JavaScript library
gem 'jquery-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # JavaScript library
  gem 'jquery-ui-rails'
  
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  
  # For nice looking buttons
  gem 'sassy-buttons'
  
  # compass uses this for sprites
  gem 'chunky_png'

  # native c library for png routines to speed up chunky_png
  gem 'oily_png'
end

group :development do
  # YARD documentation library
  gem 'yard'
  gem 'yard-rspec'

  # To interpret markdown
  gem 'redcarpet'
end

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'

  # Remove deprecation error
  gem 'thin'
  
  # User interaction simulation for testing
  gem 'capybara'
  
  # Allows Capybara to test through a browser
  gem 'launchy'
      
  # Factory gem
  gem 'factory_girl_rails'
  
  # For testing JavaScript/Coffeescript
  gem 'jasmine'
  
  # Compiling JS for automatic Jasmine tests
  gem 'rack-asset-compiler'

  gem 'simplecov'
end

# JavaScript runtime
gem 'therubyracer'

# Gems only to be used for development
group :development do
  # Improved generators
  gem 'nifty-generators'
end

# Enable HAML format views.  Prettier than ERB format views, I find.
gem "haml"

# For deployment.  Phusion Passenger integrates the rails app. with Apache.
gem 'passenger'

# Beanstalkd wrapper
gem 'beanstalk-client'
gem 'stalker'

# To manage background processes
gem 'god'

# Custom utilities
gem 'dmorrill10-utils'

# Poker logic
gem 'acpc_poker_player_proxy'
gem 'acpc_dealer'
gem 'acpc_dealer_data'

# Improved forms
gem 'simple_form', "~> 1.5"

# Instant form validation
gem 'client_side_validations', '~> 3.2.0.beta.1'
gem 'client_side_validations-simple_form'
gem 'client_side_validations-mongoid', '~> 2.4.0.beta.2'

# Improved logging output
gem 'awesome_print'
