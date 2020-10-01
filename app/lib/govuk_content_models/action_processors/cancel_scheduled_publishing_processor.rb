module GovukContentModels
  module ActionProcessors
    class CancelScheduledPublishingProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
