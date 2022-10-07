module Formats
  class TransactionPresenter < EditionFormatPresenter
  private

    def schema_name
      "transaction"
    end

    def document_type
      "transaction"
    end

    def details
      {
        variants:,
        introductory_paragraph: govspeak(edition.introduction),
        start_button_text: edition.start_button_text,
        will_continue_on: edition.will_continue_on,
        transaction_start_link: edition.link,
        more_information: govspeak(edition.more_information),
        other_ways_to_apply: govspeak(edition.alternate_methods),
        what_you_need_to_know: govspeak(edition.need_to_know),
        external_related_links:,
        department_analytics_profile: edition.department_analytics_profile,
        downtime_message:,
      }.delete_if { |_, value| value.nil? }
    end

    def variants
      edition.variants.in_order.map do |variant|
        {
          title: variant.title.to_s,
          slug: variant.slug.to_s,
          introductory_paragraph: govspeak(variant.introduction),
          transaction_start_link: variant.link.to_s,
          more_information: govspeak(variant.more_information),
          other_ways_to_apply: govspeak(variant.alternate_methods),
        }.delete_if { |_, value| value.nil? }
      end
    end

    def govspeak(field)
      if field.present?
        [
          {
            content_type: "text/govspeak",
            content: field.to_s,
          },
        ]
      end
    end

    def downtime_message
      if artefact.downtime && artefact.downtime.publicise?
        artefact.downtime.message
      end
    end
  end
end
