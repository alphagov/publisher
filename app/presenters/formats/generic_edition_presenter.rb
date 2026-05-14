module Formats
  class GenericEditionPresenter < EditionFormatPresenter
    def render_for_fact_check_manager_api
      return unless @edition.respond_to?(:whole_body)

      HtmlRenderer.render_hash(fact_check_content_hash)
    end

  private

    def fact_check_content_hash
      if @edition.editionable.is_a?(Parted) && @edition.parts.any?
        @edition.parts.in_order.to_h { |part| [part.slug, { heading: part.title, body: part.body.presence }] }
      else
        { content: { heading: "Body", body: "##{@edition.title}\n#{@edition.whole_body.presence}" } }
      end
    end

    def schema_name
      "generic_with_external_related_links"
    end

    def document_type
      @artefact.kind
    end

    def path_type
      case @edition.editionable
      when TransactionEdition
        "exact"
      else
        "prefix"
      end
    end

    def details
      {
        external_related_links:,
      }
    end
  end
end
