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
      fields = {}

      if edition.fact_check_id
        fields[:access_limited] = { fact_check_ids: [edition.fact_check_id] }
      end

      fields
    end

    def required_fields(republish)
      {
        title: edition.title,
        base_path: base_path,
        description: edition.overview || "",
        schema_name: schema_name,
        document_type: artefact.kind,
        need_ids: [],
        public_updated_at: public_updated_at,
        publishing_app: "publisher",
        rendering_app: "frontend",
        routes: routes,
        redirects: [],
        update_type: update_type(republish),
        change_note: edition.latest_change_note,
        details: details,
        locale: artefact.language,
      }
    end

    def external_related_links
      edition.artefact.external_links.map do |link|
        {
          url: link["url"],
          title: link["title"]
        }
      end
    end

    def routes
      [
        { path: "#{base_path}", type: path_type },
        { path: "#{json_path}", type: "exact" }
      ]
    end

    def base_path
      "/#{edition.slug}"
    end

    def json_path
      "#{base_path}.json"
    end

    # TransactionEdition, CampaignEdition, HelpPageEdition
    # need to register exact routes...
    def path_type
      registers_exact_route? ? 'exact' : 'prefix'
    end

    # the default mode for mainstream content
    def registers_exact_route?
      false
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
  end
end
