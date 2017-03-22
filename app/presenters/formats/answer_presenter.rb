module Formats
  class AnswerPresenter < EditionFormatPresenter
  private

    def schema_name
      'answer'
    end

    def document_type
      'answer'
    end

    def rendering_app
      "government-frontend"
    end

    def details
      {
        body: [
          {
            content_type: "text/govspeak",
            content: @edition.body.to_s,
          },
        ],
        external_related_links: external_related_links,
      }
    end
  end
end
