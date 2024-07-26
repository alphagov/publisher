require "test_helper"

class PublicationsTableHelperTest < ActionView::TestCase
  include PublicationsTableHelper

  def setup
    # Draft 2
    # @publication_draft_1 = SimpleSmartAnswerEdition.new(important_note: {comment: "This is an important note"})
    # @publication_draft_1 = SimpleSmartAnswerEdition.new(title: "", panopticon_id: "Some_id", important_note: {comment: "This is an important note"})

    # @publication_draft_1 = stub(
    # @publication_draft_1 = SimpleSmartAnswerEdition.new(important_note: {comment: "This is an important note"})
    # @publication_draft_1 = SimpleSmartAnswerEdition.new(title: "", panopticon_id: "Some_id", important_note: {comment: "This is an important note"})
    # @publication_draft_1 = Edition.new(state: "draft", version_number: 1, format: "PopularLinks")

    # Draft 2
    @publication_draft_3 = stub(
      # _id: 666bfe6945dba900014b72a3,
      # created_at: 2024-06-14 08:25:13.916 UTC,
      # updated_at: 2024-06-26 10:26:42.484 UTC,
      state: "draft",
      # assigned_to_id: nil,
      # panopticon_id: nil,
      version_number: 1,
      # sibling_in_progress: nil,
      # title: "popular links",
      # in_beta: false,
      # publish_at: nil,
      # overview: nil,
      # slug: nil,
      # rejected_count: 0,
      # assignee: nil,
      # reviewer: nil,
      # creator: nil,
      # publisher: nil,
      # archiver: nil,
      # major_change: false,
      # change_note: nil,
      # review_requested_at: nil,
      # auth_bypass_id: "db95b296-a6ff-4d1f-9e67-42c2b536ddc5",
      # _type: "PopularLinksEdition"
      format: "PopularLinks", # NB: doesn't exist in DB query!?
      important_note: {comment: "This is an important note"}, # NB: doesn't exist in DB query!?
      # link_items: [{"title"=>"title1", "url"=>"https://bbc.com"}, {"title"=>"title2", "url"=>"https://bbc.com"}, {"title"=>"title3", "url"=>"https://bbc.com"}, {"title"=>"title4", "url"=>"https://bbc.com"}, {"title"=>"title5", "url"=>"https://bbc.com"}, {"title"=>"title6", "url"=>"https://bbc.com"}]
    )

    # Draft 3
    @publication_draft_2 = stub(
      # created_at: 2024-07-11 10:38:14.712 UTC,
      # updated_at: 2024-07-11 10:38:18.801 UTC,
      state: "draft",
      # assigned_to_id: BSON::ObjectId('66911dbf2c88ee0001d8af62'),
      # panopticon_id: "668fb6165dc0b0001d178d95",
      version_number: 2,
      # sibling_in_progress: nil,
      # title: "A draft thing",
      # in_beta: false,
      # publish_at: nil,
      # overview: "",
      # slug: "a-draft-thing",
      # rejected_count: 0,
      # assignee: "Vladimir Lenin",
      # reviewer: nil,
      # creator: "Test user",
      # publisher: nil,
      # archiver: nil,
      # major_change: false,
      # change_note: nil,
      # review_requested_at: nil,
      # auth_bypass_id: "ce86ebc1-7ee5-48f6-9580-8e9a77df4d61",
      # _type: "TransactionEdition",
      format: "Transaction", # NB: doesn't exist in DB query!?
      important_note: {comment: "This is an important note"}, # NB: doesn't exist in DB query!?
      # introduction: "",
      # will_continue_on: "",
      # link: nil,
      # more_information: "",
      # need_to_know: "",
      # department_analytics_profile: "",
      # alternate_methods: "",
      # start_button_text: "Start now">
    )
  end

  context "edition_number" do
    should "return the correct values for supplied publications" do
      assert_equal edition_number(@publication_draft_3), "1"
    end
  end

<<<<<<< HEAD
  context "format" do
    should "return the correct values for supplied publications" do
      assert_equal format(@publication_draft_3), "Popular links"
    end
  end
=======
  context "#important_note" do
    should "return the important note text for an edition" do
      user = FactoryBot.create(:user, name: "Keir")
      edition = FactoryBot.create(:edition)
      user.record_note(edition, "This is an important note", Action::IMPORTANT_NOTE)

      assert_equal "This is an important note", important_note(edition)
    end
  end

  # TODO: How to stub value for "format"?
  # context "#format" do
  #   should "return the correct value for the format" do
  #     edition = FactoryBot.create(
  #       :edition,
  #       _type: "SimpleSmartAnswerEdition"
  #     )

  #     assert_equal "Simple smart answer", format(edition)
  #   end
  # end
>>>>>>> 1fa27795 (- Add test for `important_note` method)

  # TODO
  # context "important_note" do
  #   should "return the correct values for supplied publications" do
  #     assert_equal important_note(@publication_draft_3), "This is not an important note"
  #   end
  # end
end

# Draft 1
#<SimpleSmartAnswerEdition _id: 6576f5c0d1a520001c1f4f90created_at: 2023-12-11 11:42:56.596 UTCupdated_at: 2023-12-12 10:17:33.516 UTC
# state: "draft"
# assigned_to_id: BSON::ObjectId('66911dbf2c88ee0001d8af62')
# panopticon_id: "6576f5c0d1a520001c1f4f8e"
# version_number: 1
# sibling_in_progress: nil
# title: "Test Smart Answer"
# in_beta: false
# publish_at: nil
# overview: "Some stuff"
# slug: "test-smart-answer"
# rejected_count: 0
# assignee: "Vladimir Lenin"
# reviewer: nil
# creator: "Test user"
# publisher: nil
# archiver: nil
# major_change: false
# change_note: nil
# review_requested_at: nil
# auth_bypass_id: "ddcbbf7e-cc2f-4512-812e-aac877a85655"
# _type: "SimpleSmartAnswerEdition"
# body: "The body of the thing"
# start_button_text: "Start now">

# Draft 3
#<TransactionEdition _id: 668fb6165dc0b0001d178d97,
# created_at: 2024-07-11 10:38:14.712 UTC,
# updated_at: 2024-07-11 10:38:18.801 UTC,
# state: "draft",
# assigned_to_id: BSON::ObjectId('66911dbf2c88ee0001d8af62'),
# panopticon_id: "668fb6165dc0b0001d178d95",
# version_number: 1,
# sibling_in_progress: nil,
# title: "A draft thing",
# in_beta: false,
# publish_at: nil,
# overview: "",
# slug: "a-draft-thing",
# rejected_count: 0,
# assignee: "Vladimir Lenin",
# reviewer: nil,
# creator: "Test user",
# publisher: nil,
# archiver: nil,
# major_change: false,
# change_note: nil,
# review_requested_at: nil,
# auth_bypass_id: "ce86ebc1-7ee5-48f6-9580-8e9a77df4d61",
# _type: "TransactionEdition",
# introduction: "",
# will_continue_on: "",
# link: nil,
# more_information: "",
# need_to_know: "",
# department_analytics_profile: "",
# alternate_methods: "",
# start_button_text: "Start now">
