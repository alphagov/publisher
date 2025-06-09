module GovukContentModels
  module ActionProcessors
    class AssignProcessor < BaseProcessor
      def process
        edition.assign_attributes(assigned_to_id: action_attributes[:recipient_id])
        # Need to dig deeper into this whether we save it to db or persist in memory, looks like set was doing an update which was updating and saving in the db
        edition.save!
      end
    end
  end
end
