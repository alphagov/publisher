module GovukContentModels
  module ActionProcessors
    class BaseProcessor
      alias_method :record_action_without_noise, :record_action
      alias_method :record_action_without_validation_without_noise, :record_action_without_validation

      def record_action
        new_action = record_action_without_noise
        make_record_action_noises(new_action, action_name)
      end

      def record_action_without_validation
        new_action = record_action_without_validation_without_noise
        make_record_action_noises(new_action, action_name)
      end

    private

      def make_record_action_noises(new_action, action_name)
        NoisyWorkflow.make_noise(new_action).deliver_now
        NoisyWorkflow.request_fact_check(new_action).deliver_now if action_name.to_s == "send_fact_check"
      end
    end
  end
end
