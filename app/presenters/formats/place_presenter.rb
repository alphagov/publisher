module Formats
  class PlacePresenter < EditionFormatPresenter
  private

    def schema_name
      'place'
    end

    def document_type
      'place'
    end

    def details
      details = { external_related_links: external_related_links }

      details[:place_type] = edition.place_type if edition.place_type

      %i(introduction more_information need_to_know).each do |field|
        next if edition[field].blank?

        details[field] = [
          {
            content_type: "text/govspeak",
            content: edition[field]
          }
        ]
      end

      details
    end
  end
end
