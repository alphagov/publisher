module GovukContentModels
  module ActionProcessors
    class SendFactCheckProcessor < BaseProcessor
      def process
        return false if action_attributes[:email_addresses].blank?

        if Flipflop.enabled?(:fact_check_manager_api)
          form = action_attributes[:fact_check_request_form]
          return false unless form.valid?(:send) && Services.fact_check_manager_api.post_fact_check(**form.post_new_request_payload)
        end

        action_attributes[:comment] ||= "Fact check requested"

        edition.send_fact_check
      rescue GdsApi::HTTPErrorResponse => e
        Rails.logger.error "API Error Response for Edition id #{edition.id}: #{e.class} #{e.message}"
        false
      end

    private

      def record_action
        # Request form does not need to be persisted in the Action record
        action_attributes.delete(:fact_check_request_form)

        super
      end

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
