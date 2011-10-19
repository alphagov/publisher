require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase
  def template_user_and_published_transaction
    without_metadata_denormalisation(Transaction) do
      user = User.create(:name => "Ben")
      other_user = User.create(:name => "James")
      expectation = Expectation.create :css_class=>"card_payment",  :text=>"Credit card required"
      
      transaction = user.create_publication(:transaction)
      edition = transaction.editions.first
      edition.expectation_ids = [expectation.id]
      transaction.save
    
      user.request_review(edition, {:comment => "Review this guide please."})
      other_user.okay(edition, {:comment => "I've reviewed it"})
      user.publish(edition, {:comment => "Let's go"})
      return user, transaction
    end
  end
  
  test "permits the creation of new editions" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.latest_edition.is_published?
  
    reloaded_transaction = Transaction.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction.latest_edition)

    assert new_edition.container.editions.first.changed.empty?
    assert new_edition.save
  end
  
  test "fails gracefully when creating new edition fails" do
    user, transaction = template_user_and_published_transaction
    assert transaction.persisted?
    assert transaction.latest_edition.is_published?
  
    reloaded_transaction = Transaction.find(transaction.id)
    new_edition = user.new_version(reloaded_transaction.latest_edition)
    reloaded_transaction.editions.first.expectation_ids = [1,2,3]
    assert ! new_edition.save
  end
end