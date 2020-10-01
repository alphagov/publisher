module GovukContentModels
  module ActionProcessors
    class RequestAmendmentsProcessor < BaseProcessor
      def process?
        return false unless actor.govuk_editor?

        if edition.in_review?
          requester_different?
        else
          true
        end
      end
    end
  end
end
