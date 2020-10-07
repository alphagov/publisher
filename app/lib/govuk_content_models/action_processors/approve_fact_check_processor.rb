module GovukContentModels
  module ActionProcessors
    class ApproveFactCheckProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
