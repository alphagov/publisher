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
    should "return a presenter for Answers" do
      result = EditionPresenterFactory.presenter_class("AnswerEdition")
      assert result == "Formats::AnswerPresenter"
    end

    should "return a presenter for Completed Transactions" do
      result = EditionPresenterFactory.presenter_class("CompletedTransactionEdition")
      assert result == "Formats::CompletedTransactionPresenter"
    end

    should "return a presenter for Help pages" do
      result = EditionPresenterFactory.presenter_class("HelpPageEdition")
      assert result == "Formats::HelpPagePresenter"
    end

    should "return a presenter for LocalTransactions" do
      result = EditionPresenterFactory.presenter_class("LocalTransactionEdition")
      assert result == "Formats::LocalTransactionPresenter"
    end

    should "return a presenter for SimpleSmartAnswers" do
      result = EditionPresenterFactory.presenter_class("SimpleSmartAnswerEdition")
      assert result == "Formats::SimpleSmartAnswerPresenter"
    end

    should "return default presenter for other pages" do
      result = EditionPresenterFactory.presenter_class("any_other_format")
      assert result == "Formats::GenericEditionPresenter"
    end
  end
end
