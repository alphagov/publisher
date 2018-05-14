class PublishService
  GDS_ORGANISATION_ID = "af07d5a5-df63-4ddc-9383-6a666845ebe9".freeze

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

      Services.publishing_api.patch_links(
        content_id,
        links: {
          "primary_publishing_organisation" => [GDS_ORGANISATION_ID]
        }
      )
    end
  end
end
