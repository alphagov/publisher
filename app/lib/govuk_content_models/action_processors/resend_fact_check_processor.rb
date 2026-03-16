module GovukContentModels
  module ActionProcessors
    class ResendFactCheckProcessor < BaseProcessor
      def process
        return false unless edition.latest_status_action.is_fact_check_request?

        if Flipflop.enabled?(:fact_check_manager_api)
          FactCheckManagerApiService.resend_fact_check_emails(@edition)
        end

        edition.resend_fact_check
      rescue GdsApi::HTTPErrorResponse => e
        Rails.logger.error "Error #{e.class} #{e.message}"
        false
      end

    private

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
