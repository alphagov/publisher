module Formats
  class GuidePresenter < EditionFormatPresenter
  private

    def schema_name
      'guide'
    end

    def document_type
      'guide'
    end

    def details
      {
        parts: parts,
        external_related_links: external_related_links,
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
