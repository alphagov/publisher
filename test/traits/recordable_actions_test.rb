require "test_helper"

class ModelWithRecordableActions
  include Mongoid::Document
  include RecordableActions

  attr_accessor :subsequent_siblings
end

class RecordableActionsTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:object_under_test) { ModelWithRecordableActions.create }
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

      assert_equal created_at, object_under_test.published_at
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

      object_under_test.subsequent_siblings = subsequent_editions

      assert_equal expected_superseded_at, object_under_test.superseded_at
    end

    it "returns nil when there are no subsequent editions" do
      object_under_test.subsequent_siblings = []

      assert_nil object_under_test.superseded_at
    end

    it "returns nil when the first subsequent edition is not published" do
      unpublished_edition = stub("Edition", published_at: nil)
      object_under_test.subsequent_siblings = [unpublished_edition]

      assert_nil object_under_test.superseded_at
    end
  end
end
