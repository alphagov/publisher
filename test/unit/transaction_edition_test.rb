require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase
  def template_user_and_published_transaction
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")
    expectation = Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"

    transaction = user.create_publication(:transaction)
    edition = transaction.editions.first
    edition.expectation_ids = [expectation.id]
    transaction.save

    edition.start_work
    edition.update_attributes :introduction => "Example", :link => 'http://example.com', :more_information => 'More information'
    user.request_review(edition, {:comment => "Review this guide please."})
    other_user.approve_review(edition, {:comment => "I've reviewed it"})
    user.publish(edition, {:comment => "Let's go"})
    return user, transaction
  end

  test "permits the creation of new editions" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.latest_edition.published?

    reloaded_transaction = Transaction.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction.latest_edition)

    assert new_edition.container.editions.first.changed.empty?
    assert new_edition.save
  end

  test "fails gracefully when creating new edition fails" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.latest_edition.published?

    reloaded_transaction = Transaction.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction.latest_edition)
    reloaded_transaction.editions.first.expectation_ids = [1,2,3]
    assert ! new_edition.save
  end

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
