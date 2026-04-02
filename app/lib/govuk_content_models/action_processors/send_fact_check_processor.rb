module GovukContentModels
  module ActionProcessors
    class SendFactCheckProcessor < BaseProcessor
      def process
        return false if action_attributes[:email_addresses].blank?

        if Flipflop.enabled?(:fact_check_manager_api)
          FactCheckWorker.perform_async(@edition.id, @actor.id, action_attributes[:email_addresses])
        end

        action_attributes[:comment] ||= "Fact check requested"

        edition.send_fact_check
      end

    private

      def notify_about_event(new_action)
        super

        # TODO: when we fully migrate to the new fact check manager, remove this
        unless Flipflop.enabled?(:fact_check_manager_api)
          EventNotifierService.request_fact_check(new_action)
        end
      end
    end
  end
end
