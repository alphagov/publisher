module Formats
  class PopularLinksPresenter
    # Unlike presenters for other models which inherit from editions model,
    # PopularLinksPresenter does not inherit from EditionFormatPresenter
    # This is because Edition presenter has dependency on Artefact and
    # Popular links are not coupled with Artefact unlike any other models.
    # Hence the difference
    def initialize(popular_links_edition)
      @popular_links_edition = popular_links_edition
    end

    def render_for_publishing_api(*)
      required_fields.merge optional_fields
    end

  private

    attr_reader :popular_links_edition

    def required_fields
      {
        title: popular_links_edition.title,
        schema_name: "link_collection",
        document_type: "link_collection",
        publishing_app: "publisher",
        rendering_app: "frontend",
        details:,
      }
    end

    def details
      {
        link_items: get_schema_ready_link_items,
      }
    end

    def optional_fields
      access_limited = { auth_bypass_ids: [popular_links_edition.auth_bypass_id] }
      { access_limited:, public_updated_at: public_updated_at.rfc3339(3) }
    end

    def public_updated_at
      popular_links_edition.updated_at
    end

    def get_schema_ready_link_items
      popular_links_edition.link_items.map(&:symbolize_keys)
    end
  end
end
