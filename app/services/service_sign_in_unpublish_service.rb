class ServiceSignInUnpublishService
  class << self
    def call(content_id, locale)
      Services.publishing_api.unpublish(
        content_id,
        locale: locale,
        type: "gone",
        discard_drafts: true,
      )
    end
  end
end
