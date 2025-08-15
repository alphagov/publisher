module GovukContentModels
  module ActionProcessors
    class AssignProcessor < BaseProcessor
      def process
        edition.assign_attributes(assigned_to_id: action_attributes[:recipient_id])
        edition.save!
      end
    end
  end
end
