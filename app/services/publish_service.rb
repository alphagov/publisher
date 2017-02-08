class PublishService
  class << self
    def call(edition)
      edition.register_with_rummager

      publish_current_draft(edition)
      create_new_draft(edition)
    end

  private

    def publish_current_draft(edition)
      PublishingAPIPublisher.perform_async(edition.id.to_s)
    end

    def create_new_draft(edition)
      PublishingAPIUpdater.perform_async(edition.id.to_s)
    end
  end
end
