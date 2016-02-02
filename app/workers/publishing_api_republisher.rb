class PublishingAPIRepublisher
  include Sidekiq::Worker

  def perform(*args)
    PublishingAPIUpdater.new.perform(*args)
    PublishingAPIPublisher.new.perform(*args)
  end
end
