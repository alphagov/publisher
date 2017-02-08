class UpdateService
  class << self
    def call(edition)
      create_or_update_draft(edition)
    end

  private

    def create_or_update_draft(edition)
      PublishingAPIUpdater.perform_async(edition.id.to_s)
    end
  end
end
