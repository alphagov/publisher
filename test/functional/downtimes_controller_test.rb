require "test_helper"
require "support/downtimes_controller_parameterised_tests"

class DowntimesControllerTest < ActionController::TestCase
  extend DowntimesControllerParameterisedTests

  setup do
    login_as_stub_user
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
      should "not create a downtime when model validation fails" do
        post :create, params: { edition_id: edition.id, downtime: invalid_params }
        assert_that_no_downtime_exists
      end

      should "not create a downtime when extra date/time validation fails" do
        params_with_invalid_start_time = downtime_params.merge('start_time(1i)': "aaa")

        post :create, params: { edition_id: edition.id, downtime: params_with_invalid_start_time }

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

      test_create_with_invalid_datetime_values

      should "display a validation error when the start date is invalid" do
        params_with_invalid_start_time = downtime_params.merge('start_time(1i)': "4", 'start_time(2i)': "31")

        post :create, params: { edition_id: edition.id, downtime: params_with_invalid_start_time }

        assert_select "div.govuk-error-summary" do
          assert_select "a", "Start time format is invalid"
        end
      end

      should "not display other datetime validation errors when there are 'format is invalid' errors" do
        params_with_invalid_start_time = downtime_params.merge('end_time(1i)': "a")

        post :create, params: { edition_id: edition.id, downtime: params_with_invalid_start_time }

        assert_select "div.govuk-error-summary" do
          assert_select "a", "End time format is invalid"
          assert_select "a", { text: "End time must be in the future", count: 0 }
        end
      end

      should "run model validations when there are datetime validation errors" do
        params_with_invalid_start_time = downtime_params.merge('end_time(1i)': "a", message: "")

        post :create, params: { edition_id: edition.id, downtime: params_with_invalid_start_time }

        assert_select "div.govuk-error-summary" do
          assert_select "a", "End time format is invalid"
          assert_select "a", "Message can't be blank"
        end
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
        put :update, params: { edition_id: edition.id, commit: "Cancel downtime" }
      end

      should "redirect to the downtime index" do
        DowntimeRemover.stubs(:destroy_immediately)
        put :update, params: { edition_id: edition.id, commit: "Cancel downtime" }
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

  context "#index" do
    should "list all published transaction editions" do
      unpublished_transaction_edition = FactoryBot.create(:transaction_edition, title: "unpublished transaction")
      transaction_editions = FactoryBot.create_list(:transaction_edition, 2, :published)

      get :index

      assert_response :ok
      assert_select ".govuk-table__cell", count: 0, text: unpublished_transaction_edition.title
      transaction_editions.each do |edition|
        assert_select ".govuk-table__cell", text: edition.editionable.title
      end
    end

    should "redirect to root page if welsh_editor" do
      login_as_welsh_editor

      get :index

      assert_response :redirect
      assert_redirected_to root_path
      assert_includes flash[:danger], "do not have permission"
    end
  end

  context "#destroy" do
    should "render the page ok" do
      create_downtime
      get :destroy, params: { edition_id: edition.id }
      assert_response :ok
    end
  end

  def edition
    @edition ||= FactoryBot.create(:transaction_edition)
  end

  def downtime
    @downtime ||= FactoryBot.create(:downtime, artefact_id: edition.artefact.id)
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

  def assert_a_downtime_is_created
    assert_equal 1, Downtime.count
  end

  def assert_that_no_downtime_exists
    assert_equal 0, Downtime.count
  end
end
