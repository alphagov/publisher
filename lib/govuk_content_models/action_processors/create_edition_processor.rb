module GovukContentModels
  module ActionProcessors
    class CreateEditionProcessor < BaseProcessor
      def action_name
        Action::CREATE
      end

      def process
        format = event_attributes[:format]
        format_name = "#{format}_edition" unless format.to_s =~ /edition$/
        publication_class = format_name.to_s.camelize.constantize
        @edition = publication_class.create(event_attributes[:edition_attributes])
      end

      def record_action?
        edition.persisted?
      end
    end
  end
end
