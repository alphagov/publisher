module Formats
  class ServiceSignInPresenter
    attr_reader :content

    def initialize(content)
      @content = content.deep_symbolize_keys
    end

    def render_for_publishing_api
      payload = {
        schema_name: "service_sign_in",
        rendering_app: "government-frontend",
        publishing_app: "publisher",
        document_type: "service_sign_in",
        locale: locale,
        update_type: update_type,
        change_note: change_note,
        base_path: base_path,
        routes: routes,
        title: title,
        description: description,
      }
      payload[:public_updated_at] = public_updated_at if public_updated_at.present?
      payload
    end

  private

    def locale
      content[:locale]
    end

    def update_type
      content[:update_type]
    end

    def change_note
      content[:change_note]
    end

    def base_path
      "/#{parent_slug}/sign-in"
    end

    def routes
      [
        { path: base_path.to_s, type: "prefix" },
      ]
    end

    def title
      parent.title
    end

    def description
      parent.overview
    end

    def public_updated_at
      DateTime.now.rfc3339 if update_type == "major"
    end

    def parent
      @parent ||= Edition.where(slug: parent_slug).last
    end

    def parent_slug
      content[:start_page_slug]
    end
  end
end
