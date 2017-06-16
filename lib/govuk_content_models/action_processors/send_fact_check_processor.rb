module GovukContentModels
  module ActionProcessors
    class SendFactCheckProcessor < BaseProcessor
      def process
        return false if action_attributes[:email_addresses].blank?
        action_attributes[:comment] ||= "Fact check requested"

        edition.send_fact_check
      end
    end
  end
end
