module Formats
  class TransactionPresenter < EditionFormatPresenter
  private

    def schema_name
      'transaction'
    end

    def document_type
      'transaction'
    end

    def details
      {
        introductory_paragraph: govspeak(:introduction),
        will_continue_on: edition.will_continue_on,
        transaction_start_link: edition.link,
        more_information: govspeak(:more_information),
        other_ways_to_apply: govspeak(:alternate_methods),
        what_you_need_to_know: govspeak(:need_to_know),
        external_related_links: external_related_links,
        department_analytics_profile: edition.department_analytics_profile
      }.delete_if { |_, value| value.nil? }
    end

    def govspeak(field)
      if edition.send(field).present?
        [
          {
            content_type: "text/govspeak",
            content: edition.send(field).to_s
          }
        ]
      end
    end
  end
end
