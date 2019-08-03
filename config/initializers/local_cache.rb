require 'redis_config'
require "redis"
config = RedisConfig.config_for(:local_cache)
LocalCache = Redis::Namespace.new(config[:namespace], redis: Redis.new(config))
LocalCache.select(config[:db])
