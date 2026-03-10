module Formats
  class GenericEditionPresenter < EditionFormatPresenter
    def render_for_fact_check_manager_api
      return unless @edition.respond_to?(:whole_body)

      HtmlRenderer.render_hash({ body: @edition.whole_body.presence || "" })
    end

  private

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
