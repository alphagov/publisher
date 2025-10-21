module Formats
  class GuidePresenter < EditionFormatPresenter
  private

    def schema_name
      "guide"
    end

    def document_type
      "guide"
    end

    def rendering_app
      "frontend"
    end

    def details
      {
        parts:,
        external_related_links:,
        hide_chapter_navigation: edition.hide_chapter_navigation.present?,
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
            },
          ],
        }
      end
    end
  end
end
