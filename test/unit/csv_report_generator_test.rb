require "test_helper"

class CsvReportGeneratorTest < ActiveSupport::TestCase
  setup do
    @report_dir = File.join(Dir.tmpdir, 'publisher-test-reports')
    CsvReportGenerator.stubs(:csv_path).returns(@report_dir)
    @generator = CsvReportGenerator.new
  end

  teardown do
    FileUtils.rm_rf(@report_dir)
  end

  test "#path makes a temp directory and returns the path" do
    Timecop.freeze(Time.mktime(2015, 1)) do
      Process.stubs(:pid).returns 1234
      expected = File.join(Dir.tmpdir, "publisher_reports-20150101000000-1234")
      assert_equal expected, @generator.path

      # Check the call is memoized
      FileUtils.expects(:mkdir_p).never
      assert_equal expected, @generator.path

      assert Dir.exist?(@generator.path)
    end
  end

  test "all reports are able to create CSVs" do
    @generator.reports.each do |report|
      assert_respond_to(report, :write_csv)
    end
  end

  test "#move_temporary_reports_into_place does what it says" do
    FileUtils.mkdir_p(CsvReportGenerator.csv_path)

    dest = File.join(CsvReportGenerator.csv_path, "example.csv")
    File.open(dest, "w") do |f|
      f.write("foo")
    end

    File.open(File.join(@generator.path, "example.csv"), "w") do |f|
      f.write("bar")
    end

    @generator.move_temporary_reports_into_place

    assert_equal "bar", File.read(
      File.join(CsvReportGenerator.csv_path, "example.csv"))
  end
end
