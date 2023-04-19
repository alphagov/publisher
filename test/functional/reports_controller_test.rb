require "test_helper"

class ReportsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user

    last_modified = Time.zone.local(2023, 12, 12, 1, 1, 1)

    Aws.config[:s3] = {
      stub_responses: {
        head_object: { last_modified: },
      },
    }

    ENV["REPORTS_S3_BUCKET_NAME"] = "example"
  end

  teardown do
    ENV["REPORTS_S3_BUCKET_NAME"] = nil
  end

  test "it redirects the user to S3" do
    get :progress

    assert_equal 302, response.status
  end

  test "shows the last updated time on the index page" do
    get :index

    assert_match(/Generated 1:01am, 12 December 2023/, response.body)
  end
end
