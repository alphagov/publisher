module GovukContentModels
  module ActionProcessors
    class ArchiveProcessor < BaseProcessor
      def process?
        actor.govuk_editor?
      end
    end
  end
end
