module GovukContentModels
  module ActionProcessors
    class ResendFactCheckProcessor < BaseProcessor
      def process
        return false unless edition.latest_status_action.is_fact_check_request?

        if Flipflop.enabled?(:fact_check_manager_api) && !action_attributes[:fact_check_request_form].resend_fact_check_emails
          return false
        end

        edition.resend_fact_check
      rescue GdsApi::HTTPErrorResponse => e
        Rails.logger.error "API Error Response for Edition #{edition.id}: #{e.class} #{e.message}"
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
          EventNotifierService.resend_fact_check(new_action)
        end
      end
    end
  end
end
