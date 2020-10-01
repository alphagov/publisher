module GovukContentModels
  module ActionProcessors
    class ApproveReviewProcessor < BaseProcessor
      def process?
        actor.govuk_editor? && requester_different?
      end
    end
  end
end
