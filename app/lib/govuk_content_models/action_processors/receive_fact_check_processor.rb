module GovukContentModels
  module ActionProcessors
    class ReceiveFactCheckProcessor < BaseProcessor
      # Always records the action.
      def process
        # Using action_attributes to keep this block limited to API calls as a temporary measure
        # Safe assumption that the old script-triggered flow is avoiding raising exception for a reason
        # TODO: This class needs properly refactoring when we retire the old non-API flow
        if @action_attributes[:requester_name] && @edition.state != "fact_check"
          @edition.errors.add(:state, "Edition is not in a state where fact check can be submitted")
          return false
        end

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
