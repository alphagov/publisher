module Formats
  class LocalTransactionPresenter < EditionFormatPresenter
  private

    def schema_name
      'local_transaction'
    end

    def details
      required_details
      .merge(optional_details)
      .merge(external_related_links: external_related_links)
    end

    def registers_exact_route?
      false
    end

  private

    def required_details
      {
        lgsl_code: edition.lgsl_code,
        service_tiers: service_tiers,
      }
    end

    def optional_details
      {}.merge(lgil_override)
        .merge(introduction)
        .merge(more_information)
        .merge(need_to_know)
    end

    def lgil_override
      return {} if edition.lgil_override.nil?

      { lgil_override: edition.lgil_override }
    end

    def introduction
      return {} if edition.introduction.nil?

      {
        introduction: [
          {
            content_type: "text/govspeak",
            content: edition.introduction,
          }
        ]
      }
    end

    def more_information
      return {} if edition.more_information.nil?

      {
        more_information: [
          {
            content_type: "text/govspeak",
            content: edition.more_information,
          }
        ]
      }
    end

    def need_to_know
      return {} if edition.need_to_know.nil?

      {
        need_to_know: [
          {
            content_type: "text/govspeak",
            content: edition.need_to_know,
          }
        ]
      }
    end

    def service_tiers
      edition.service.providing_tier if edition.service
    end
  end
end
