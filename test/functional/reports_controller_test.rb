require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @report_dir = File.join(Dir.tmpdir, 'publisher-test-reports')
    CsvReportGenerator.stubs(:csv_path).returns(@report_dir)
    path = File.join(@report_dir, "editorial_progress.csv")

    FileUtils.mkdir_p(@report_dir)
    File.open(path, "w") { |f| f.write("foo,bar") }
    FileUtils.touch(path, mtime: Time.mktime(2015, 6, 1))
  end

  teardown do
    FileUtils.rm_rf(@report_dir)
  end

  test "it sends the file with the correct name" do
    get :progress

    assert_equal "foo,bar", response.body
    assert_equal 'attachment; filename="editorial_progress-20150601010000.csv"',
      response.header["Content-Disposition"]
    assert_equal "text/csv", response.header["Content-Type"]
  end

  test "returns 404 if the report is not available" do
    get :organisation_content

    assert_equal 404, response.status
  end

  test "shows the mtime on the index page" do
    get :index

    assert_match /Generated 1:00am, 1 June 2015/,  response.body
  end
end
