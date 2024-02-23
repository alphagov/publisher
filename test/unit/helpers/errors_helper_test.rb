require "test_helper"

class ErrorsHelperTest < ActionView::TestCase
  setup do
    @object_with_no_errors = ErrorTestObject.new("title", Time.zone.today)
    @object_with_errors = ErrorTestObject.new(nil, nil)
    @object_with_unrelated_errors = ErrorTestObject.new("title", nil)
    @object_with_errors.validate
    @object_with_unrelated_errors.validate
    @flash = ActionDispatch::Flash::FlashHash.new
  end

  context "#errors_for" do
    should "return nil when there are no error messages" do
      assert_nil errors_for(@object_with_no_errors.errors, :title)
    end

    should "return errors for the attribute passed in" do
      assert_equal errors_for(@object_with_errors.errors, :title), [{ text: "Title can't be blank" }]
    end

    should "format the error message when there are multiple errors on a field" do
      assert_equal errors_for(@object_with_errors.errors, :date), [{ text: "Date can't be blank" }, { text: "Date is invalid" }]
    end

    should "return nil when object only has unrelated errors" do
      assert_nil errors_for(@object_with_unrelated_errors.errors, :title)
    end
  end

  class ErrorTestObject
    include ActiveModel::Model
    attr_accessor :title, :date

    validates :title, :date, presence: true
    validate :date_is_a_date

    def initialize(title, date)
      @title = title
      @date = date
    end

    def date_is_a_date
      errors.add(:date, :invalid) unless date.is_a?(Date)
    end
  end
end
