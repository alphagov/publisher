require "test_helper"

class PublicationsTableHelperTest < ActionView::TestCase
  include PublicationsTableHelper

  def setup
    # Draft 2
    @publication_draft = stub(
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
      # link_items: [{"title"=>"title1", "url"=>"https://bbc.com"}, {"title"=>"title2", "url"=>"https://bbc.com"}, {"title"=>"title3", "url"=>"https://bbc.com"}, {"title"=>"title4", "url"=>"https://bbc.com"}, {"title"=>"title5", "url"=>"https://bbc.com"}, {"title"=>"title6", "url"=>"https://bbc.com"}]
    )
  end

  context "edition_number" do
    should "return the correct values for supplied publications" do
      assert_equal edition_number(@publication_draft), "1"
    end
  end
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
