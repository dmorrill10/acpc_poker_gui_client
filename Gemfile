source 'https://rubygems.org'

gem 'rails', '~>3.2'

gem 'rack', '~>1.4'

gem 'acpc_table_manager', '~> 2.0'

# Enable HAML format views. Prettier than ERB format views.
gem "haml", '~> 3.1'

# For deployment. Phusion Passenger integrates the rails app. with Apache.
gem 'passenger', '~>4.0'

# To manage background processes
gem 'daemon-overlord'

# Improved logging output
gem 'awesome_print'

# For password encryption
gem 'bcrypt', '~> 3.1.5', require: "bcrypt"

group :development do
  # YARD documentation library
  gem 'yard'

  # To interpret markdown
  gem 'kramdown'

  # Better error information
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  # Not strictly necessary but makes
  # testing through a VM network much faster
  # because WeBrick needs a line of configuration
  # changed, otherwise it's impossibly slow
  gem 'thin'

  # Static code analysis
  gem 'rails_best_practices'

  gem 'pry-rails'
end
