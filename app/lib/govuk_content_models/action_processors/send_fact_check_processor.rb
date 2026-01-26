module GovukContentModels
  module ActionProcessors
    class SendFactCheckProcessor < BaseProcessor
      def process
        return false if action_attributes[:email_addresses].blank?

        if Flipflop.enabled?(:fact_check_manager_api) && FactCheckManagerApiService.request_fact_check(@edition, @actor, action_attributes[:email_addresses]).is_a?(GdsApi::HTTPErrorResponse)
          return false
        end

        action_attributes[:comment] ||= "Fact check requested"

        edition.send_fact_check
      end
    end
  end
end
