module Formats
  class LocalTransactionPresenter < EditionFormatPresenter
  private

    def schema_name
      "local_transaction"
    end

    def document_type
      "local_transaction"
    end

    def details
      required_details
        .merge(optional_details)
        .merge(external_related_links: external_related_links)
    end

    def required_details
      {
        lgsl_code: edition.lgsl_code,
        lgil_code: edition.lgil_code,
        service_tiers: service_tiers,
      }
    end

    def optional_details
      {}.merge(introduction)
        .merge(more_information)
        .merge(need_to_know)
        .merge(all_devolved_administration_availabilities)
    end

    def introduction
      return {} if edition.introduction.nil?

      {
        introduction: [
          {
            content_type: "text/govspeak",
            content: edition.introduction,
          },
        ],
      }
    end

    def more_information
      return {} if edition.more_information.nil?

      {
        more_information: [
          {
            content_type: "text/govspeak",
            content: edition.more_information,
          },
        ],
      }
    end

    def need_to_know
      return {} if edition.need_to_know.nil?

      {
        need_to_know: [
          {
            content_type: "text/govspeak",
            content: edition.need_to_know,
          },
        ],
      }
    end

    def all_devolved_administration_availabilities
      {
        scotland_availability: devolved_administration_availability(edition.scotland_availability),
        wales_availability: devolved_administration_availability(edition.wales_availability),
        northern_ireland_availability: devolved_administration_availability(edition.northern_ireland_availability),
      }.compact
    end

    def devolved_administration_availability(availability)
      if availability.type == "devolved_administration_service"
        { type: "devolved_administration_service", alternative_url: availability.alternative_url }
      elsif availability.type == "unavailable"
        { type: "unavailable" }
      end
    end

    def service_tiers
      edition.service.providing_tier if edition.service
    end
  end
end
