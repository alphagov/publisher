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
        .merge(external_related_links:)
    end

    def required_details
      {
        lgsl_code: edition.lgsl_code,
        lgil_code: edition.lgil_code,
        service_tiers:,
      }
    end

    def optional_details
      {}.merge(introduction)
        .merge(cta_text: edition.cta_text || "")
        .merge(more_information)
        .merge(need_to_know)
        .merge(before_results)
        .merge(after_results)
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

    def before_results
      return {} if edition.before_results.nil?

      {
        before_results: [
          {
            content_type: "text/govspeak",
            content: edition.before_results,
          },
        ],
      }
    end

    def after_results
      return {} if edition.after_results.nil?

      {
        after_results: [
          {
            content_type: "text/govspeak",
            content: edition.after_results,
          },
        ],
      }
    end

    def all_devolved_administration_availabilities
      {
        scotland_availability: devolved_administration_availability(edition.editionable.scotland_availability),
        wales_availability: devolved_administration_availability(edition.editionable.wales_availability),
        northern_ireland_availability: devolved_administration_availability(edition.editionable.northern_ireland_availability),
      }.compact
    end

    def devolved_administration_availability(availability)
      case availability.authority_type
      when "devolved_administration_service"
        { type: "devolved_administration_service", alternative_url: availability.alternative_url }
      when "unavailable"
        { type: "unavailable" }
      end
    end

    def service_tiers
      edition.service.providing_tier if edition.service
    end
  end
end
