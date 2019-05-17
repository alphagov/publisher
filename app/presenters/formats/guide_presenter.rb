module Formats
  class GuidePresenter < EditionFormatPresenter
  private # rubocop:disable Layout/IndentationWidth

    def schema_name
      'guide'
    end

    def document_type
      'guide'
    end

    def rendering_app
      "government-frontend"
    end

    def details
      {
        parts: parts,
        external_related_links: external_related_links,
        hide_chapter_navigation: !!edition.hide_chapter_navigation
      }
    end

    def parts
      edition.parts.in_order.map do |part|
        {
          title: part.title.to_s,
          slug: part.slug.to_s,
          body: [
            {
              content_type: "text/govspeak",
              content: part.body.to_s,
            }
          ]
        }
      end
    end
  end
end
