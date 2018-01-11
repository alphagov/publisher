require "test_helper"
require "gds_api/test_helpers/link_checker_api"

class LinkCheckReportsControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::LinkCheckerApi
  include Rails.application.routes.url_helpers

  setup do
    login_as_stub_user
    @edition = FactoryGirl.create(:place_edition, introduction: "[link](https://www.gov.uk)")
  end

  context "#create" do
    setup do
      @stubbed_api_request = link_checker_api_create_batch(
        uris: ["https://www.gov.uk"],
        id: "a-batch-id",
        webhook_uri: link_checker_api_callback_url(host: Plek.find("publisher")),
        webhook_secret_token: Rails.application.secrets.link_checker_api_secret_token
      )
    end

    should "create and link report and redirect on a normal request" do
      post :create, params: { edition_id: @edition.id }

      @edition.reload

      assert_redirected_to(controller: "editions", action: "show", id: @edition.id)
      assert @edition.link_check_reports.any?
      assert "a-batch-id", @edition.link_check_reports.last.batch_id
    end

    should "create and render the create template on AJAX" do
      post :create, params: { edition_id: @edition.id }, xhr: true

      assert_response :success
      assert_template :create

      @edition.reload

      assert @edition.link_check_reports.any?
      assert "a-batch-id", @edition.link_check_reports.last.batch_id
    end
  end
end
