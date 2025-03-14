module GovukContentModels
  module ActionProcessors
    class SkipReviewProcessor < BaseProcessor
      def process?
        actor.skip_review? and !requester_different?
      end
    end
  end
end
