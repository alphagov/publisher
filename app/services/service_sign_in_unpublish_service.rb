class ServiceSignInUnpublishService
  class << self
    def call(content_id, locale, redirect_path: nil)
      @content_id = content_id
      @locale = locale
      if redirect_path.present?
        unpublish_redirect(redirect_path)
      else
        unpublish_gone
      end
    end

  private

    def base_path
      content_item["base_path"]
    end

    def content_item
      @content_item ||= Services.publishing_api.get_content(
        @content_id,
        locale: @locale,
      )
    end

    def unpublish_gone
      Services.publishing_api.unpublish(
        @content_id,
        locale: @locale,
        type: "gone",
        discard_drafts: true,
      )
    end

    def unpublish_redirect(redirect_path)
      Services.publishing_api.unpublish(
        @content_id,
        locale: @locale,
        type: "redirect",
        discard_drafts: true,
        redirects: [
          {
            path: base_path,
            type: "prefix",
            destination: redirect_path,
          },
        ],
      )
    end
  end
end
