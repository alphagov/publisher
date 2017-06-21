module GovukContentModels
  module ActionProcessors
    class NewVersionProcessor < BaseProcessor
      def process?
        edition.published?
      end

      def process
        convert_to = event_attributes[:convert_to]
        @edition = if !convert_to.nil?
                     edition.build_clone(convert_to.to_s.camelize.constantize)
                   else
                     edition.build_clone
                   end

        @edition.save(validate: false) if record_action?
      end

      def record_action?
        !!edition
      end
    end
  end
end
