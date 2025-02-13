require "aws-sdk-s3"
require "test_helper"

class ReportTest < ActiveSupport::TestCase
  def setup
    @stubbed_s3_client = Aws::S3::Client.new(stub_responses: true)
    Aws::S3::Client.stubs(:new).returns(@stubbed_s3_client)

    @bucket_name = "my-test-bucket"
  end

  context "#filename" do
    should "return filename with extension" do
      report = Report.new("example")
      assert_equal "example.csv", report.filename
    end
  end

  context "#upload_to_s3" do
    should "call put object to S3" do
      expected_put_object_request = {
        bucket: @bucket_name,
        key: "example.csv",
        body: "body",
        checksum_algorithm: "CRC32",
      }

      ClimateControl.modify REPORTS_S3_BUCKET_NAME: @bucket_name do
        report = Report.new("example")
        report.upload_to_s3("body")
      end

      assert_equal 1, @stubbed_s3_client.api_requests.size
      assert_equal expected_put_object_request, @stubbed_s3_client.api_requests.first[:params]
    end
  end

  context "#last_updated" do
    should "return nil if object not present" do
      @stubbed_s3_client.stub_responses(:head_object, "NotFound")

      ClimateControl.modify REPORTS_S3_BUCKET_NAME: @bucket_name do
        report = Report.new("example")
        assert_nil report.last_updated
      end
    end

    should "return with date if object present" do
      last_modified = Time.zone.local(2023, 12, 12, 1, 1, 1)
      @stubbed_s3_client.stub_responses(:head_object, { last_modified: })

      ClimateControl.modify REPORTS_S3_BUCKET_NAME: @bucket_name do
        report = Report.new("example")
        assert_equal last_modified, report.last_updated
      end
    end
  end

  context "#url" do
    should "return a presigned URL for the csv" do
      ClimateControl.modify REPORTS_S3_BUCKET_NAME: @bucket_name do
        report = Report.new("example")
        assert report.url.starts_with?("https://#{@bucket_name}.s3.us-stubbed-1.amazonaws.com/example.csv")
      end
    end
  end
end
