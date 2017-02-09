module Formats
  class AnswerPresenter < EditionFormatPresenter
  private

    def schema_name
      'answer'
    end

    def details
      {
        body: [
          {
            content_type: "text/govspeak",
            content: @edition.body,
          },
        ],
        external_related_links: external_related_links,
      }
    end

    def registers_exact_route?
      true
    end
  end
end
