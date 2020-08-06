module GovukContentModels
  module ActionProcessors
    class RequestAmendmentsProcessor < BaseProcessor
      def process?
        if edition.in_review?
          requester_different?
        else
          true
        end
      end
    end
  end
end
