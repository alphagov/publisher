class PublishingAPIRepublisher
  include Sidekiq::Worker

  def perform(*args)
    PublishingAPIUpdater.new.call(*args)
    PublishingAPIPublisher.new.call(*args)
  end
end
