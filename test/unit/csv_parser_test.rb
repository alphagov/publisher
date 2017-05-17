require "test_helper"

class CSVParserTest < ActiveSupport::TestCase
  test "should raise an exception if the file is empty" do
    parser = CSVParser.new(StringIO.new(""))

    assert_raises(RuntimeError) { parser.parse }
  end

  test "can convert a CSV into an Array of Hash objects" do
    csv_string = <<EOS
slug,tag
/foo,/bar
EOS

    parser = CSVParser.new(StringIO.new(csv_string))

    assert_equal [{ slug: "/foo", tag: "/bar" }], parser.parse
  end
end
