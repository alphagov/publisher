module GovukContentModels
  module ActionProcessors
    class AssignProcessor < BaseProcessor
      def process
        edition.set(assigned_to_id: action_attributes[:recipient_id])
        edition.reload
      end
    end
  end
end
