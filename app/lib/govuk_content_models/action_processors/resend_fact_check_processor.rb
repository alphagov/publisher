module GovukContentModels
  module ActionProcessors
    class ResendFactCheckProcessor < BaseProcessor
      def process
        return false unless edition.latest_status_action.is_fact_check_request?

        edition.resend_fact_check
      end

    private

      def notify_about_event(new_action)
        super

        EventNotifierService.resend_fact_check(new_action)
      end
    end
  end
end
