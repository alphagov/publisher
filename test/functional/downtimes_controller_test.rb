require 'test_helper'

class DowntimesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#index" do
    should "list all published transaction editions" do
      unpublished_transaction_edition = FactoryBot.create(:transaction_edition)
      transaction_editions = FactoryBot.create_list(:transaction_edition, 2, :published)

      get :index

      assert_response :ok
      assert_select 'h4.publication-table-title', count: 0, text: unpublished_transaction_edition.title
      transaction_editions.each do |edition|
        assert_select 'h4.publication-table-title', text: edition.title
      end
    end
  end

  context "#new" do
    should "render the page ok" do
      get :new, params: { edition_id: edition.id }
      assert_response :ok
    end
  end

  context "#create" do
    context "with valid params" do
      should "create a new downtime" do
        DowntimeScheduler.stubs(:schedule_publish_and_expiry)
        post :create, params: { edition_id: edition.id, downtime: downtime_params }
        assert_a_downtime_is_created
      end

      should "schedule the publication and expiration of the downtime" do
        DowntimeScheduler.expects(:schedule_publish_and_expiry)
        post :create, params: { edition_id: edition.id, downtime: downtime_params }
      end

      should "redirect to the downtime index page" do
        DowntimeScheduler.stubs(:schedule_publish_and_expiry)
        post :create, params: { edition_id: edition.id, downtime: downtime_params }
        assert_redirected_to controller: "downtimes", action: "index"
      end
    end

    context "with invalid params" do
      should "not create a downtime" do
        post :create, params: { edition_id: edition.id, downtime: invalid_params }
        assert_that_no_downtime_exists
      end

      should "not schedule publishing and expiration" do
        DowntimeScheduler.expects(:schedule_publish_and_expiry).never
        post :create, params: { edition_id: edition.id, downtime: invalid_params }
      end

      should "rerender the page" do
        post :create, params: { edition_id: edition.id, downtime: invalid_params }
        assert_template :new
      end
    end
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
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: 'Cancel downtime' }
      end

      should "redirect to the downtime index" do
        DowntimeRemover.stubs(:destroy_immediately)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: 'Cancel downtime' }
        assert_redirected_to controller: "downtimes", action: "index"
      end
    end

    context "rescheduling planned downtime" do
      should "schedule the changes for publication and expiration" do
        DowntimeScheduler.expects(:schedule_publish_and_expiry).with(downtime)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: 'Re-schedule downtime message' }
      end

      should "redirect to the downtime index" do
        create_downtime
        DowntimeScheduler.stubs(:schedule_publish_and_expiry)
        put :update, params: { edition_id: edition.id, downtime: downtime_params, commit: 'Re-schedule downtime message' }
        assert_redirected_to controller: "downtimes", action: "index"
      end
    end

    context "with invalid form data" do
      should "rerender the page" do
        create_downtime
        put :update, params: { edition_id: edition.id, downtime: invalid_params, commit: 'Re-schedule downtime message' }
        assert_template :edit
      end
    end
  end

  def edition
    @_edition ||= FactoryBot.create(:transaction_edition)
  end

  def downtime
    @_downtime ||= FactoryBot.create(:downtime, artefact: edition.artefact)
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
      'start_time(5i)': 00,
      'start_time(3i)': 14,
      'start_time(2i)': 3,
      'start_time(1i)': next_year,
      'end_time(4i)': 15,
      'end_time(5i)': 00,
      'end_time(3i)': 14,
      'end_time(2i)': 3,
      'end_time(1i)': next_year,
      'message': 'foo'
    }
  end

  def invalid_params
    downtime_params.merge('end_time(1i)': last_year)
  end

  def assert_a_downtime_is_created
    assert_equal 1, Downtime.count
  end

  def assert_that_no_downtime_exists
    assert_equal 0, Downtime.count
  end
end
