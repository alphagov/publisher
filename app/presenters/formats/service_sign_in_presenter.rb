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
        details: details,
      }
      payload[:public_updated_at] = public_updated_at if public_updated_at.present?
      payload
    end

    def content_id
      @content_id ||= existing_content_id || SecureRandom.uuid
    end

    def links
      {
        parent: [parent.content_id]
      }
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

    def details
      {
        choose_sign_in: choose_sign_in,
        create_new_account: create_new_account,
      }
    end

    def choose_sign_in
      {
        title: content[:choose_sign_in][:title],
        slug: content[:choose_sign_in][:slug],
        description: govspeak_content(content[:choose_sign_in][:description]),
        options: options,
      }
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
        body: govspeak_content(content[:create_new_account][:body])
      }
    end

    def govspeak_content(content)
      [
        {
          content_type: "text/govspeak",
          content: content,
        }
      ]
    end

    def parent
      @parent ||= Edition.where(slug: parent_slug).last
    end

    def parent_slug
      content[:start_page_slug]
    end

    def existing_content_id
      Services.publishing_api.lookup_content_id(base_path: base_path)
    end
  end
end
