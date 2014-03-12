require "sidekiq"

redis_config = YAML.load_file(Rails.root.join("config", "redis.yml"))

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.server_middleware do |chain|
    chain.add Sidekiq::Statsd::ServerMiddleware, env: 'govuk.app.publisher', prefix: 'workers'
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
