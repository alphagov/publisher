module GovukContentModels
  module ActionProcessors
    class PublishProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
