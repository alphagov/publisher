module Formats
  class PlacePresenter < EditionFormatPresenter
    FIELD_LABELS = {
      introduction: "Introduction",
      more_information: "Further information",
      need_to_know: "What you need to know",
    }.freeze

  private

    def schema_name
      "place"
    end

    def document_type
      "place"
    end

    def details
      details = { external_related_links: }

      details[:place_type] = edition.place_type if edition.place_type

      %i[introduction more_information need_to_know].each do |field|
        next if edition.editionable[field].blank?

        details[field] = [
          {
            content_type: "text/govspeak",
            content: edition.editionable[field],
          },
        ]
      end

      details
    end
  end
end
