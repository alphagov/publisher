module GovukContentModels
  module ActionProcessors
    class ApproveReviewProcessor < BaseProcessor
      def process?
        requester_different?
      end
    end
  end
end
