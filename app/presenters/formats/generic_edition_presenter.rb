module Formats
  class GenericEditionPresenter < EditionFormatPresenter
  private # rubocop:disable Layout/IndentationWidth

    def schema_name
      "generic_with_external_related_links"
    end

    def document_type
      @artefact.kind
    end

    def path_type
      case @edition.class
      when TransactionEdition
        "exact"
      else
        "prefix"
      end
    end

    def details
      {
        external_related_links: external_related_links,
      }
    end
  end
end
