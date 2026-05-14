module Formats
  class GuidePresenter < EditionFormatPresenter
    def render_for_fact_check_manager_api
      return unless @edition.respond_to?(:whole_body)

      if @edition.editionable.is_a?(Parted) && @edition.parts.any?
        HtmlRenderer.render_hash(@edition.parts.in_order.to_h { |part| [part.slug, { heading: part.title, body: part.body.presence }] })
      else
        super
      end
    end

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
