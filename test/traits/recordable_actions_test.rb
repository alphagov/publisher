require "test_helper"

class RecordableActionsTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:object_under_test) { FactoryBot.create(:edition) }
  let(:user) { FactoryBot.create(:user) }

  describe "#published_by" do
    it "returns who published the object" do
      object_under_test.actions.create!(
        request_type: Action::PUBLISH,
        requester: user,
      )

      assert_equal user, object_under_test.published_by
    end

    it "returns nil when there are no published actions" do
      assert_nil object_under_test.published_by
    end
  end

  describe "#published_at" do
    it "returns when the object was created" do
      created_at = Time.zone.now - 4.days
      object_under_test.actions.create!(
        request_type: Action::PUBLISH,
        requester: user,
        created_at:,
      )

      assert_in_delta created_at, object_under_test.published_at, 1
    end

    it "returns nil when there are no published actions" do
      assert_nil object_under_test.published_at
    end
  end

  describe "#superseded_at" do
    it "returns when the object was superseded by another edition" do
      expected_superseded_at = Time.zone.now - 3.days

      subsequent_editions = 4.times.map { stub("Edition") }
      subsequent_editions.first.stubs(:published_at).returns(expected_superseded_at)

      object_under_test.stubs(:subsequent_siblings).returns(subsequent_editions)

      assert_equal expected_superseded_at, object_under_test.superseded_at
    end

    it "returns nil when there are no subsequent editions" do
      object_under_test.stubs(:subsequent_siblings).returns([])

      assert_nil object_under_test.superseded_at
    end

    it "returns nil when the first subsequent edition is not published" do
      unpublished_edition = stub("Edition", published_at: nil)
      object_under_test.stubs(:subsequent_siblings).returns([unpublished_edition])

      assert_nil object_under_test.superseded_at
    end
  end

  describe "#latest_status_action" do
    it "returns the action of that type even when a newer action of a different type exists" do
      edition = FactoryBot.create(:edition, :in_review)
      edition.new_action(user, Action::SEND_FACT_CHECK)

      assert_equal Action::REQUEST_REVIEW, edition.latest_status_action(Action::REQUEST_REVIEW).request_type
    end

    it "returns nil when no action of that type exists" do
      edition = FactoryBot.create(:edition, :in_review)

      assert_nil edition.latest_status_action(Action::SEND_FACT_CHECK)
    end

    it "returns the latest status action when no type argument provided" do
      edition = FactoryBot.create(:edition, :in_review)
      edition.new_action(user, Action::SEND_FACT_CHECK)
      edition.new_action(user, Action::REQUEST_AMENDMENTS)
      edition.new_action(user, Action::IMPORTANT_NOTE)

      assert_equal Action::REQUEST_AMENDMENTS, edition.latest_status_action.request_type
    end
  end
end
