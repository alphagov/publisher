module GovukContentModels
  module ActionProcessors
    class CreateEditionProcessor < BaseProcessor
      def action_name
        Action::CREATE
      end

      def process?
        actor.govuk_editor?
      end

      # Return value is used in caller chain to show errors
      def process
        publication_class_attributes = []
        edition_attributes = []
        format = event_attributes[:format]
        format_name = "#{format}_edition" unless format.to_s.match?(/edition$/)
        publication_class = format_name.to_s.camelize.constantize
        event_attributes[:edition_attributes].each do |attributes|
          publication_class_attributes << attributes if publication_class.has_attribute?(attributes[0])
          edition_attributes << attributes if Edition.has_attribute?(attributes[0])
        end

        editionable = publication_class.build(publication_class_attributes.to_h)
        @edition = Edition.build(edition_attributes.to_h)
        @edition.editionable = editionable
        @edition.save! if @edition.valid?
        @edition
      end

      def record_action?
        edition.persisted?
      end
    end
  end
end
