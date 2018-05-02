module Formats
  class CompletedTransactionPresenter < EditionFormatPresenter
  private

    PROMOTIONS = %w(organ_donor register_to_vote mot_reminder).freeze

    def schema_name
      'completed_transaction'
    end

    def document_type
      'completed_transaction'
    end

    def details
      return optional_details.merge(required_details) if PROMOTIONS.include?(promotion_choice["choice"])
      required_details
    end

    def required_details
      {
        external_related_links: external_related_links
      }
    end

    def optional_details
      {
        promotion: {
          category: promotion_choice.fetch("choice"),
          url: promotion_choice.fetch("url", '')
        }
      }
    end

    def promotion_choice
      edition.presentation_toggles["promotion_choice"]
    end
  end
end
