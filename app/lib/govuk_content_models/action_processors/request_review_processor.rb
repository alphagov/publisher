module GovukContentModels
  module ActionProcessors
    class RequestReviewProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
