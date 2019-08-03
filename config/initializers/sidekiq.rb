redis_conf = RedisConfig.config_for(:sidekiq)
redis_conn = proc { Redis::Namespace.new(redis_conf[:namespace], redis: Redis.new(redis_conf)) }

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 5, &redis_conn)
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 20, &redis_conn)
end

Sidekiq::Extensions.enable_delay!
