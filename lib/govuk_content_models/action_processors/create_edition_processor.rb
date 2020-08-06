module GovukContentModels
  module ActionProcessors
    class CreateEditionProcessor < BaseProcessor
      def action_name
        Action::CREATE
      end

      # Return value is used in caller chain to show errors
      # rubocop:disable Rails/SaveBang
      def process
        format = event_attributes[:format]
        format_name = "#{format}_edition" unless format.to_s.match?(/edition$/)
        publication_class = format_name.to_s.camelize.constantize
        @edition = publication_class.create(event_attributes[:edition_attributes])
      end
      # rubocop:enable Rails/SaveBang

      def record_action?
        edition.persisted?
      end
    end
  end
end
