require "test_helper"

class CsvReportGeneratorTest < ActiveSupport::TestCase
  setup do
    @stubbed_s3_client = Aws::S3::Client.new(stub_responses: true)
    Aws::S3::Client.stubs(:new).returns(@stubbed_s3_client)

    @generator = CsvReportGenerator.new
  end

  test "editions_active_in_past_two_years returns editions created with past two years in desc order" do
    user = FactoryBot.create(:user, :govuk_editor, name: "")
    edition1 = FactoryBot.create(
      :transaction_edition,
      title: "Bringing your pet dog, cat or ferret to Great Britain",
      slug: "bring-pet-to-great-britain",
      created_at: Time.zone.now - 1.year,
      updated_at: Time.zone.now - 1.year,
      assigned_to_id: user.id,
    )
    edition2 = FactoryBot.create(
      :transaction_edition,
      title: "Register to vote (armed forces)",
      slug: "register-to-vote-armed-forces",
      created_at: Time.zone.now - 1.day,
      updated_at: Time.zone.now - 1.day,
      assigned_to_id: user.id,
    )
    # This older edition should be excluded from results
    FactoryBot.create(
      :transaction_edition,
      title: "Old GOV.UK page",
      slug: "old-gov-uk-page",
      created_at: Time.zone.now - 3.years,
      updated_at: Time.zone.now - 3.years,
      assigned_to_id: user.id,
    )

    editions = @generator.editions_active_in_past_two_years.to_a
    assert_equal 2, editions.count
    assert_equal edition2.title, editions[0].title
    assert_equal edition1.title, editions[1].title
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
