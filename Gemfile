source 'http://rubygems.org'

gem 'rails', '3.1.1'

gem 'rack', '1.3.3'

# Database library
gem "mongoid", "= 2.3.0"
gem 'bson', '= 1.4.0'
gem 'bson_ext', '= 1.4.0'
#gem "bson_ext", "~> 1.4"
#gem 'sqlite3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
  
  # For convenient styling macros
  gem 'compass', '~> 0.12.alpha'       # also using the compass framework for SASS
  
  # For nice looking buttons
  gem 'sassy-buttons', '= 0.0.7'
  gem 'chunky_png'    # compass uses this for sprites
  gem 'oily_png'      # native c library for png routines to speed up chunky_png
end

# To interpret Coffeescript in HAML
gem 'coffee-filter'

# JavaScript library
gem 'jquery-rails'

# To use ActiveModel has_secure_password @todo lookup whether this is better or viable, or helpful at all
# gem 'bcrypt-ruby', '~> 3.0.0'

# Deploy with Capistrano @todo lookup whether this is better or viable, or helpful at all
# This would basically replace my 'update_production_server.rb, might be useful sometime
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

# Testing and development gems
group :development, :test do
  # Pretty printed test output
  gem 'turn', :require => false
  
  # Testing framework
  gem 'rspec-rails'
  
  # Testing framework overtop of RSpec that simulates user interaction
  gem 'capybara'
  
  # Allows Capybara to test through a browser
  gem 'launchy'
  
  # Mock object and method stubbing framework
  gem 'mocha'
  
  # To make Guard more efficient on Linux
  gem 'rb-inotify'
  gem 'libnotify'
  
  # Automatically run tests with Guard
  gem 'guard-rspec'
  
  # Automatically run bundler to install gems when this Gemfile changes
  gem 'guard-bundler'
  
  # Factory gem
  gem 'factory_girl_rails'
  
  # For testing JavaScript/Coffeescript
  gem 'jasmine'
  
  # Compiling JS for automatic Jasmine tests
   gem 'rack-asset-compiler'
end

# JavaScript runtime
gem 'therubyracer'

# Gems only to be used for development
group :development do
  # Improved generators
  gem 'nifty-generators'
  gem 'pry'
end

# Enable HAML format views.  Prettier than ERB format views, I find.
gem "haml"

# YARD documentation library
gem 'yard'
gem 'yard-rspec'

# For deployment.  Phusion Passenger integrates the rails app. with Apache.
gem 'passenger'

# Beanstalkd wrapper
gem 'beanstalk-client'
gem 'stalker'

# To manage background processes
gem 'god'

# Improved forms
gem 'simple_form'

# Poker logic
gem 'acpc_poker_types'
gem 'acpc_poker_match_state'
gem 'acpc_poker_basic_proxy'
gem 'acpc_poker_player_proxy'

# Instant form validation
gem 'client_side_validations'
