module RedisConfig
  REDIS_CONFIG = {
    host: ENV['REDIS_HOST'] || '127.0.0.1',
    port: ENV['REDIS_PORT'] || 6379,
    namespace: 'publisher'
  }
end
