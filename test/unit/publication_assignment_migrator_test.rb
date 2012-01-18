require 'test_helper'
require 'user'

class PublicationAssignmentMigratorTest < ActiveSupport::TestCase

  test "can migrate edition assignment" do
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

    guide = FactoryGirl.create(:guide)
    alice, bob = %w[alice bob].map { |u| FactoryGirl.create(:user, name: u) }

    class << alice
      def assign(edition, recipient)
        record_action edition, __method__, recipient: recipient
      end
    end

    # We'll run the assigns query the old way (using some monkey patching)
    alice.assign(guide.editions.first, bob)

    assert_equal([], Publication.assigned_to(bob).to_a)
    assert_equal([guide], Publication.legacy_assignment_filter(bob).to_a)

    # Now we'll migrate the lot
    PublicationAssignmentMigrator.migrate_all

    # Let's see how it went
    assert_equal([guide], Publication.assigned_to(bob).to_a)
    assert_equal([guide], Publication.legacy_assignment_filter(bob).to_a)
  end

end