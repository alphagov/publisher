module Formats
  class LocalTransactionPresenter < EditionFormatPresenter
  private

    def schema_name
      'local_transaction'
    end

    def details
      {
        lgsl_code: edition.lgsl_code,
        lgil_override: edition.lgil_override,
        service_tiers: service_tiers,
        introduction: [
          {
            content_type: "text/govspeak",
            content: edition.introduction,
          },
        ],
        more_information: [
          {
            content_type: "text/govspeak",
            content: edition.more_information,
          },
        ],
        need_to_know: [
          {
            content_type: "text/govspeak",
            content: edition.need_to_know,
          },
        ],
        external_related_links: external_related_links,
      }
    end

    def registers_exact_route?
      false
    end

    def service_tiers
      edition.service.providing_tier if edition.service
    end
  end
end
