module Formats
  class CompletedTransactionPresenter < EditionFormatPresenter
  private

    PROMOTIONS = %w(organ_donor register_to_vote mot_reminder electric_vehicle).freeze

    def schema_name
      "completed_transaction"
    end

    def document_type
      "completed_transaction"
    end

    def details
      optional_details.merge(required_details)
    end

    def required_details
      { external_related_links: external_related_links }
    end

    def optional_details
      { promotion: promotion_details }.compact
    end

    def promotion_details
      return unless PROMOTIONS.include?(promotion_choice["choice"])

      { category: promotion_choice.fetch("choice") }
        .merge(
          promotion_choice
            .slice("url", "opt_in_url", "opt_out_url")
            .symbolize_keys
            .compact,
        )
    end

    def promotion_choice
      edition.presentation_toggles["promotion_choice"]
    end
  end
end
