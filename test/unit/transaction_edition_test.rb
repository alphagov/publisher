require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase

  def transaction_edition
    expectation = Expectation.create :css_class => "card_payment",  :text => "Credit card required"
    edition = TransactionEdition.new(:title => "Transaction", :slug => "transaction", :panopticon_id => FactoryGirl.create(:artefact).id)
    edition.expectation_ids = [expectation.id]
    edition.update_attributes(:introduction => "Example", :link => 'http://example.com', :more_information => 'More information')
    edition.save!
    edition
  end

  test "a new edition of a transaction creates a diff when published" do
    stub_register_published_content

    without_metadata_denormalisation(AnswerEdition) do
      user = User.create :name => 'Thomas'

      edition_one = transaction_edition
      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.introduction = "Changed content"

      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "http://example.com\n\n{\"Example\" >> \"Changed content\"}\n\nMore information", publish_action.diff

    end
  end
end
