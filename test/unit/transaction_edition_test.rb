require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase
  def template_user_and_published_transaction
    user = User.create(:name => "Ben")
    other_user = User.create(:name => "James")
    expectation = Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"

    transaction = user.create_whole_edition(:transaction)
    transaction.expectation_ids = [expectation.id]
    transaction.save

    transaction.start_work
    transaction.save
    user.request_review(transaction, {:comment => "Review this guide please."})
    transaction.save
    other_user.approve_review(transaction, {:comment => "I've reviewed it"})
    transaction.save
    user.publish(transaction, {:comment => "Let's go"})
    transaction.save
    return user, transaction
  end

  test "permits the creation of new editions" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.published?

    reloaded_transaction = TransactionEdition.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction)

    assert new_edition.save
  end

  test "fails gracefully when creating new edition fails" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.published?

    reloaded_transaction = TransactionEdition.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction)
    reloaded_transaction.expectation_ids = [1,2,3]
    assert ! new_edition.save
  end
end
