module GovukContentModels
  module ActionProcessors
    class NewVersionProcessor < BaseProcessor
      def process?
        edition.published? || edition.archived?
      end

      def process
        convert_to = event_attributes[:convert_to]
        @edition = if !convert_to.nil?
                     edition.build_clone(convert_to.to_s.camelize.constantize)
                   else
                     edition.build_clone
                   end

        @edition.artefact.update_from_edition(@edition) \
          if @edition.artefact.archived?

        @edition.save(validate: false) if record_action?
      end

      def record_action?
        !!edition
      end
    end
  end
end
