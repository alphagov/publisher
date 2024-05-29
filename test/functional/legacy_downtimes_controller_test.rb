require "test_helper"

class LegacyDowntimesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#edit" do
    should "render the page ok" do
      create_downtime
      get :edit, params: { edition_id: edition.id }
      assert_response :ok
    end
  end

  context "#update" do
    context "cancelling scheduled downtime" do
      should "invoke the DowntimeRemover" do
        DowntimeRemover.expects(:destroy_immediately).with(downtime)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: "Cancel downtime" }
      end

      should "redirect to the downtime index" do
        DowntimeRemover.stubs(:destroy_immediately)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: "Cancel downtime" }
        assert_redirected_to controller: "downtimes", action: "index"
      end
    end

    context "rescheduling planned downtime" do
      should "schedule the changes for publication and expiration" do
        DowntimeScheduler.expects(:schedule_publish_and_expiry).with(downtime)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: "Re-schedule downtime message" }
      end

      should "redirect to the downtime index" do
        create_downtime
        DowntimeScheduler.stubs(:schedule_publish_and_expiry)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: "Re-schedule downtime message" }
        assert_redirected_to controller: "downtimes", action: "index"
      end
    end

    context "with invalid form data" do
      should "rerender the page" do
        create_downtime
        put :update, params: { edition_id: edition.id, downtime: invalid_params, commit: "Re-schedule downtime message" }
        assert_template :edit
      end
    end
  end

  def edition
    @edition ||= FactoryBot.create(:transaction_edition)
  end

  def downtime
    @downtime ||= FactoryBot.create(:downtime, artefact: edition.artefact)
  end

  def create_downtime
    downtime
  end

  def next_year
    (Time.zone.now + 1.year).year
  end

  def last_year
    (Time.zone.now - 1.year).year
  end

  def downtime_params
    {
      'artefact_id': edition.artefact.id,
      'start_time(4i)': 11,
      'start_time(5i)': 0,
      'start_time(3i)': 14,
      'start_time(2i)': 3,
      'start_time(1i)': next_year,
      'end_time(4i)': 15,
      'end_time(5i)': 0,
      'end_time(3i)': 14,
      'end_time(2i)': 3,
      'end_time(1i)': next_year,
      'message': "foo",
    }
  end

  def invalid_params
    downtime_params.merge('end_time(1i)': last_year)
  end
end
