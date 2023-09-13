require "test_helper"

class CsvReportGeneratorTest < ActiveSupport::TestCase
  setup do
    @stubbed_s3_client = Aws::S3::Client.new(stub_responses: true)
    Aws::S3::Client.stubs(:new).returns(@stubbed_s3_client)

    @generator = CsvReportGenerator.new
  end

  test "run! creates and uploads reports" do
    ClimateControl.modify REPORTS_S3_BUCKET_NAME: "example" do
      @generator.run!
    end

    assert_equal 7, @stubbed_s3_client.api_requests.size
    assert(@stubbed_s3_client.api_requests.all? { |r| r[:operation_name] == :put_object })
    assert(@stubbed_s3_client.api_requests.all? { |r| r[:params][:bucket] == "example" })

    assert_equal "editorial_progress.csv", @stubbed_s3_client.api_requests[0][:params][:key]
    assert_equal "edition_churn.csv", @stubbed_s3_client.api_requests[1][:params][:key]
    assert_equal "all_edition_churn.csv", @stubbed_s3_client.api_requests[2][:params][:key]
    assert_equal "organisation_content.csv", @stubbed_s3_client.api_requests[3][:params][:key]
    assert_equal "content_workflow.csv", @stubbed_s3_client.api_requests[4][:params][:key]
    assert_equal "all_content_workflow.csv", @stubbed_s3_client.api_requests[5][:params][:key]
    assert_equal "all_urls.csv", @stubbed_s3_client.api_requests[6][:params][:key]
  end
end
