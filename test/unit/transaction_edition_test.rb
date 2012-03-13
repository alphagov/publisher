require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase

  test "a new edition of a transaction creates a diff when published" do
    without_metadata_denormalisation(Answer) do
      user, transaction = template_user_and_published_transaction

      edition_two = transaction.published_edition.build_clone
      edition_two.save!
      edition_two.introduction = "Changed content"
      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last
      assert_equal "http://example.com\n\n{\"Example\" >> \"Changed content\"}\n\nMore information", publish_action.diff
    end
  end
  
end
