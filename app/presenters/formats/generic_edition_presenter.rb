module Formats
  class GenericEditionPresenter < EditionFormatPresenter
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
