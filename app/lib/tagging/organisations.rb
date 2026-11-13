module Tagging
  class Organisations
    def organisations
      get_organisation_details
    end

  private

    def get_organisation_details
      linkables = Tagging::Linkables.new
      linkable_org_contend_ids = linkables.organisations.map(&:last)
      filtered_organisations = retrieve_details_from_api["results"].reject do |organisation|
        linkable_org_contend_ids.exclude?(organisation["content_id"])
      end

      filtered_organisations.map do |item|
        {
          title: item["title"],
          acronym: item.dig("details", "acronym"),
          content_id: item["content_id"],
        }
      end
    end

    def retrieve_details_from_api
      Services.publishing_api.get_content_items(
        document_type: "organisation",
        per_page: 2000,
        publication_state: "published",
        fields: %w[title content_id details],
      )
    end
  end
end
