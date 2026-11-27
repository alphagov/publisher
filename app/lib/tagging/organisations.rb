module Tagging
  class Organisations
    def organisations
      get_organisation_details
    end

  private

    def get_organisation_details
      linkables = Tagging::Linkables.new
      linkable_org_content_ids = linkables.organisations.map(&:last)
      filtered_organisations = retrieve_details_from_api["results"].select do |organisation|
        linkable_org_content_ids.include?(organisation["content_id"])
      end

      filtered_organisations.map { |item|
        {
          title: item["title"],
          acronym: item.dig("details", "acronym"),
          state: item["publication_state"],
          content_id: item["content_id"],
        }
      }.sort_by { |item| item[:title].downcase }
    end

    def retrieve_details_from_api
      Services.publishing_api.get_content_items(
        document_type: "organisation",
        per_page: 5000,
        states: %w[published draft],
        fields: %w[title publication_state content_id details],
      )
    end
  end
end
