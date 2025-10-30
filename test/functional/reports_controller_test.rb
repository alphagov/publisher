require "test_helper"

class ReportsControllerTest < ActionController::TestCase
  context "When reports are available" do
    setup do
      login_as_stub_user

      last_modified = Time.zone.local(2023, 12, 12, 1, 2, 3)

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

    should "redirect the user to S3 when following report links" do
      %i[
        progress
        organisation_content
        edition_churn
        all_edition_churn
        content_workflow
        recent_content_workflow
        all_urls
      ].each do |action|
        get action

        assert_equal 302, response.status
      end
    end

    should "show the last updated time on the index page" do
      get :index

      assert_select "ul.gem-c-document-list__item-metadata" do
        assert_select "li.gem-c-document-list__attribute", { count: 7, text: "Generated 1:02am" }
        assert_select "li.gem-c-document-list__attribute", { count: 7, text: "12 December 2023" }
      end
    end
  end

  context "When reports are not available" do
    setup do
      login_as_stub_user

      Aws.config[:s3] = {
        stub_responses: {
          head_object: "NotFound",
        },
      }

      ENV["REPORTS_S3_BUCKET_NAME"] = "example"
    end

    teardown do
      ENV["REPORTS_S3_BUCKET_NAME"] = nil
    end

    should "indicate that reports are not available on the index page" do
      get :index

      assert_select "ul.gem-c-document-list__item-metadata" do
        assert_select "li.gem-c-document-list__attribute", { count: 7, text: "Report currently unavailable" }
      end
    end
  end
end
