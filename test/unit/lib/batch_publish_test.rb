require 'test_helper'

class BatchPublishTest < ActiveSupport::TestCase
  setup do
    @user = FactoryGirl.create(:user)
    stub_register_published_content
  end

  should "invoke publish on the supplied editions" do
    edition = FactoryGirl.create(:edition, slug: "foo", version_number: 1, state: "ready", body: "x")
    edition_identifiers = [
      { slug: "foo", edition: 1 }
    ]
    BatchPublish.new(edition_identifiers, @user.email).call
    assert_equal "published", edition.reload.state
  end

  context "an edition is already published" do
    should "not try to publish it" do
      edition = FactoryGirl.create(:edition, slug: "foo", version_number: 1, state: "published", body: "x")
      edition.expects(:publish).never
      edition_identifiers = [
        { slug: "foo", edition: 1 }
      ]
      BatchPublish.new(edition_identifiers, @user.email).call
      assert_equal "published", edition.reload.state
    end
  end

  context "edition doesn't exist" do
    should "fail noisily" do
      edition_identifiers = [
        { slug: "not-foo", edition: 1 }
      ]
      assert_raises RuntimeError do
        BatchPublish.new(edition_identifiers, @user.email).call
      end
    end
  end

  context "an edition is not 'Ready' yet" do
    should "fail noisily" do
      edition = FactoryGirl.create(:edition, slug: "foo", version_number: 1, state: "draft", body: "x")
      edition.expects(:publish).never
      edition_identifiers = [
        { slug: "foo", edition: 1 }
      ]
      assert_raises RuntimeError do
        BatchPublish.new(edition_identifiers, @user.email).call
      end
      assert_equal "draft", edition.reload.state
    end
  end

  context "one of the editions cannot be found" do
    should "not try to publish any of the editions" do
      edition = FactoryGirl.create(:edition, slug: "foo", version_number: 1, state: "ready", body: "x")
      Edition.any_instance.expects(:publish).never
      edition_identifiers = [
        { slug: "foo", edition: 1 },
        { slug: "not-foo", edition: 1 }
      ]
      assert_raises RuntimeError do
        BatchPublish.new(edition_identifiers, @user.email).call
      end
      assert_equal "ready", edition.reload.state
    end
  end
end
