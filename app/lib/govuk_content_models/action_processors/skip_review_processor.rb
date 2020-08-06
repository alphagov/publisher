module GovukContentModels
  module ActionProcessors
    class SkipReviewProcessor < BaseProcessor
      def process?
        actor.permissions.include?("skip_review")
      end
    end
  end
end
