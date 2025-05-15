module Formats
  class EditionFormatPresenter
    def initialize(edition)
      @edition = edition
      @artefact = edition.artefact
    end

    def render_for_publishing_api(republish: false)
      required_fields(republish).merge optional_fields
    end

  private

    attr_reader :edition, :artefact

    def optional_fields
      access_limited = { auth_bypass_ids: [edition.auth_bypass_id] }
      phase = edition.in_beta ? "beta" : nil

      { access_limited:, phase: }.compact
    end

    def required_fields(republish)
      {
        title: edition.title,
        base_path:,
        description: edition.overview || "",
        schema_name:,
        document_type:,
        public_updated_at: public_updated_at.rfc3339(3),
        last_edited_by_editor_id:,
        publishing_app: "publisher",
        rendering_app:,
        routes:,
        redirects: [],
        update_type: update_type(republish),
        change_note: edition.latest_change_note,
        details:,
        locale: artefact.language,
      }.compact
    end

    def schema_name
      "override me"
    end

    def document_type
      "override me"
    end

    def details
      {}
    end

    def rendering_app
      "frontend"
    end

    def external_related_links
      artefact.external_links.map do |link|
        {
          url: link["url"],
          title: link["title"],
        }
      end
    end

    def routes
      [
        { path: base_path.to_s, type: path_type },
      ]
    end

    def base_path
      "/#{edition.slug}"
    end

    # TransactionEdition, HelpPageEdition
    # need to register exact routes...
    def path_type
      edition.exact_route? ? "exact" : "prefix"
    end

    def update_type(republish)
      if republish
        "republish"
      elsif major_change?
        "major"
      else
        "minor"
      end
    end

    def major_change?
      edition.major_change || edition.version_number == 1
    end

    def public_updated_at
      edition.public_updated_at || edition.updated_at
    end

    # We can't reliably get the exact user who last edited the edition,
    # so we rely on who created the edition, which is a fair enough
    # approximation
    def last_edited_by_editor_id
      edition.created_by&.uid
    end
  end
end
