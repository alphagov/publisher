module GovukContentModels
  module ActionProcessors
    class ReceiveFactCheckProcessor < BaseProcessor
      # Always records the action.
      def process
        edition.perform_event_without_validations(:receive_fact_check)
        # Fact checks are processed async, so the user doesn't get an opportunity
        # to retry without the content that (inadvertantly) fails validation, which happens frequently.
        record_action_without_validation
      end

      def record_action?
        false
      end
    end
  end
end
