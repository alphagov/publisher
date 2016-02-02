class PublishingApiRepublisher
  include Sidekiq::Worker

  def perform(*args)
    PublishingAPIUpdater.new.perform(*args)
    PublishingApiPublisher.new.perform(*args)
  end
end
