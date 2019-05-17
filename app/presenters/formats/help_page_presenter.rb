module Formats
  class HelpPagePresenter < EditionFormatPresenter
  private # rubocop:disable Layout/IndentationWidth

    def schema_name
      'help_page'
    end

    def document_type
      'help_page'
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
