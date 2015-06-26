require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    path = File.join(CsvReportGenerator::CSV_PATH, "editorial_progress.csv")

    FakeFS.activate!

    # Needed to render the index response
    FakeFS::FileSystem.clone(File.join(Rails.root, "app/views"))
    @controller.view_paths.each { |path| FakeFS::FileSystem.clone(path) }

    FileUtils.mkdir_p(CsvReportGenerator::CSV_PATH)
    Timecop.freeze(Time.mktime(2015,1,1)) do
      File.open(path, "w") { |f| f.write("foo,bar") }
    end
  end

  teardown do
    FakeFS.deactivate!
  end

  test "it sends the file with the correct name" do
    get :progress

    assert_equal "foo,bar", response.body
    assert_equal 'attachment; filename="editorial_progress-20150101000000.csv"',
      response.header["Content-Disposition"]
    assert_equal "text/csv", response.header["Content-Type"]
  end

  test "returns 404 if the report is not available" do
    get :organisation_content

    assert_equal 404, response.status
  end

  test "shows the mtime on the index page" do
    get :index

    assert_match /Generated 12:00am, 1 January 2015/,  response.body
  end
end
