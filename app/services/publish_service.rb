class PublishService
  class << self
    def call(edition, update_type = nil)
      publish_current_draft(edition, update_type)
    end

  private

    def publish_current_draft(edition, update_type)
      content_id = edition.artefact.content_id

      Services.publishing_api.publish(
        content_id,
        update_type,
        locale: edition.artefact.language
      )
    end
  end
end
