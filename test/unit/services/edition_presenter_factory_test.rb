require "test_helper"

class EditionPresenterFactoryTest < ActiveSupport::TestCase#
  context ".get_presenter" do
    should "return an object" do
      edition = stub(class: "foo")
      Klass = Class.new
      Klass.expects(:new).with(edition).returns("bar")

      EditionPresenterFactory.expects(:presenter_class).with("foo").returns("EditionPresenterFactoryTest::Klass")

      result = EditionPresenterFactory.get_presenter(edition)
      assert result == "bar"
    end
  end

  context ".presenter_class" do
    should "return a presenter for Help pages" do
      result = EditionPresenterFactory.presenter_class("HelpPageEdition")
      assert result == "Formats::HelpPagePresenter"
    end

    should "return default presenter for other pages" do
      result = EditionPresenterFactory.presenter_class("any_other_format")
      assert result == "Formats::GenericEditionPresenter"
    end
  end
end
