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
        locale:,
        update_type:,
        change_note:,
        base_path:,
        routes:,
        title:,
        description:,
        details:,
      }
      payload[:public_updated_at] = public_updated_at if public_updated_at.present?
      payload
    end

    def content_id
      @content_id ||= existing_content_id || SecureRandom.uuid
    end

    def links
      {
        parent: [parent.content_id],
      }
    end

    def locale
      content[:locale]
    end

  private

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
      Time.zone.now.rfc3339 if update_type == "major"
    end

    def details
      details = { choose_sign_in: }
      if content[:create_new_account].present?
        details[:create_new_account] = create_new_account
      end
      details
    end

    def choose_sign_in
      choose_sign_in = {
        title: content[:choose_sign_in][:title],
        slug: content[:choose_sign_in][:slug],
        options:,
      }

      description = content[:choose_sign_in][:description]
      if description.present?
        choose_sign_in[:description] = govspeak_content(description)
      end

      tracking_code = content[:choose_sign_in][:tracking_code]
      tracking_domain = content[:choose_sign_in][:tracking_domain]
      tracking_name = content[:choose_sign_in][:tracking_name]
      choose_sign_in[:tracking_code] = tracking_code if tracking_code.present?
      choose_sign_in[:tracking_domain] = tracking_domain if tracking_domain.present?
      choose_sign_in[:tracking_name] = tracking_name if tracking_name.present?

      choose_sign_in
    end

    def options
      options = content[:choose_sign_in][:options]
      options.each do |option|
        if option.key?(:slug)
          option[:slug] = "#{base_path}/#{option[:slug]}"
          option[:url] = option.delete :slug
        end
      end
    end

    def create_new_account
      {
        title: content[:create_new_account][:title],
        slug: content[:create_new_account][:slug],
        body: govspeak_content(content[:create_new_account][:body]),
      }
    end

    def govspeak_content(content)
      [
        {
          content_type: "text/govspeak",
          content:,
        },
      ]
    end

    def parent
      @parent ||= Edition.where(slug: parent_slug).last
    end

    def parent_slug
      content[:start_page_slug]
    end

    def existing_content_id
      Services.publishing_api.lookup_content_id(base_path:)
    end
  end
end
