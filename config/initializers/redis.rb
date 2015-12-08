# Thanks to https://gist.github.com/pubis/1459506 for this

require 'redis'

REDIS_CONFIG = YAML.load(File.open(File.expand_path('../../redis.yml', __FILE__))).symbolize_keys

dflt = REDIS_CONFIG[:default].symbolize_keys
cnfg = if REDIS_CONFIG[Rails.env.to_sym]
  dflt.merge(REDIS_CONFIG[Rails.env.to_sym].symbolize_keys)
else
  dflt
end

$redis = Redis.new(cnfg)

# To clear out the db before each test
$redis.flushdb if Rails.env = "test"