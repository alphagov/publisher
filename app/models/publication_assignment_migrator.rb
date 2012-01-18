class PublicationAssignmentMigrator

  def self.migrate_all
    class << Publication
      def legacy_assignment_filter(user)
        expr = if user
                 %{assignment && assignment.recipient_id == "#{user.id}"}
               else
                 %{!assignment}
               end
        where(%{
      function(){
        var last = function(a){ return a && a[a.length - 1]; }
        var edition = last(this.editions);
        if (!edition) { return false; }
        var assignment = last((edition.actions || []).filter(function(a){
          return a.request_type == "#{Action::ASSIGN}";
        }));
        return #{expr};
      }
    })
      end
    end

    ActionMailer::Base.delivery_method = :test

    User.all.each do |user|
      puts "Migrating editions for user #{user.name}"

      Publication.legacy_assignment_filter(user).to_a.each do |publication|
        latest_edition = publication.latest_edition

        latest_edition.actions.find_all { |a| a.request_type == "assign" }.each do |assignment_action|
          requester = User.find(assignment_action.requester_id)
          recipient = User.find(assignment_action.recipient_id)
          puts "#{requester.name} Assigning '#{publication.name}' to #{recipient.name}"

          requester.assign(latest_edition, recipient)
        end
      end
    end
  end
end