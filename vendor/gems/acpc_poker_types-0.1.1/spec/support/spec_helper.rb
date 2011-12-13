
require 'simplecov'
SimpleCov.start

require 'mocha'

RSpec.configure do |config|
   # == Mock Framework
   config.mock_with :mocha
end
