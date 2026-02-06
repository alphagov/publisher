module GovukContentModels
  module ActionProcessors
    class SkipReviewProcessor < BaseProcessor
      def process?
        actor.skip_review? and !requester_different?
      end

    private

      def notify_about_event(new_action)
        super

        EventNotifierService.skip_review(new_action)
      end
    end
  end
end
