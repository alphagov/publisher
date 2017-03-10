module Formats
  class LicencePresenter < EditionFormatPresenter
  private

    def schema_name
      'licence'
    end

    def document_type
      'licence'
    end

    def details
      required_details
      .merge(optional_details)
      .merge(external_related_links: external_related_links)
    end

    def required_details
      {
        licence_identifier: edition.licence_identifier,
      }
    end

    def optional_details
      {}.merge(will_continue_on)
        .merge(continuation_link)
        .merge(licence_short_description)
        .merge(licence_overview)
    end

    def will_continue_on
      return {} if edition.will_continue_on.nil?

      { will_continue_on: edition.will_continue_on }
    end

    def continuation_link
      return {} if edition.continuation_link.nil?

      { continuation_link: edition.continuation_link }
    end

    def licence_short_description
      return {} if edition.licence_short_description.nil?

      { licence_short_description: edition.licence_short_description }
    end

    def licence_overview
      return {} if edition.licence_overview.nil?

      {
        licence_overview: [
          {
            content_type: "text/govspeak",
            content: edition.licence_overview,
          }
        ]
      }
    end
  end
end
