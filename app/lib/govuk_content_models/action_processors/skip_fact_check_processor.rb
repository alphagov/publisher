module GovukContentModels
  module ActionProcessors
    class SkipFactCheckProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
