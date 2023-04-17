require "aws-sdk-s3"

class Report
  def initialize(report_name)
    @bucket_name = ENV["REPORTS_S3_BUCKET_NAME"]
    @s3 = Aws::S3::Client.new

    @report_name = report_name
  end

  def filename
    "#{@report_name}.csv"
  end

  def upload_to_s3(body)
    @s3.put_object(
      bucket: @bucket_name,
      key: filename,
      body:,
    )
  end

  def last_updated
    response = @s3.head_object(bucket: @bucket_name, key: filename)
    response.last_modified
  rescue Aws::S3::Errors::NotFound
    nil
  end

  def url
    Aws::S3::Presigner.new.presigned_url(
      :get_object,
      bucket: @bucket_name,
      key: filename,
      expires_in: 5,
    )
  end
end
