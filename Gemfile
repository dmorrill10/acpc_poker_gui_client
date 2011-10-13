source 'http://rubygems.org'

gem 'rails', '3.1.1'

# Database library
gem 'sqlite3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

# JavaScript library
gem 'jquery-rails'

# To use ActiveModel has_secure_password TODO lookup whether this is better or viable, or helpful at all
# gem 'bcrypt-ruby', '~> 3.0.0'

# Deploy with Capistrano TODO lookup whether this is better or viable, or helpful at all
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
  gem 'capybara'#, :git => 'git://github.com/jnicklas/capybara.git'
  
  # Allows Capybara to test through a browser
  gem 'launchy'
  
  # Mock object and method stubbing framework
  gem 'mocha'
end

# JavaScript runtime
gem 'therubyracer'

# Websockets library
gem 'em-websocket'

# Gems only to be used for development
group :development do
  # Improved generators
  gem 'nifty-generators'
end

# Enable HAML format views.  Prettier than ERB format views, I find.
gem "haml"

# YARD documentation library
gem 'yard'

# Railroady diagramming tool.  Create SVG diagrams in the "doc" directory
# with 'rake diagram:all'.  Unfortunately, for this app, the diagrams it
# produces are not very informative.
gem 'railroady'

# For deployment.  Phusion Passenger integrates the rails app. with Apache.
gem 'passenger'

# Beanstalkd wrapper
gem 'stalker'
