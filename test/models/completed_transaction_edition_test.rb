require "test_helper"

class CompletedTransactionEditionTest < ActiveSupport::TestCase
  test "controls whether organ donor registration promotion should be displayed on a completed transaction page" do
    completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition)
    refute completed_transaction_edition.promotes_something?

    completed_transaction_edition.promotion_choice = "organ_donor"
    completed_transaction_edition.promotion_choice_url = "https://www.organdonation.nhs.uk/registration/"

    completed_transaction_edition.save!
    assert completed_transaction_edition.reload.promotes_something?

    completed_transaction_edition.promotion_choice = ''
    completed_transaction_edition.save!
    refute completed_transaction_edition.reload.promotes_something?
  end

  test "invalid if promotion_choice_url is not specified when a promotion choice is made" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition,
      promotion_choice: 'organ_donor', promotion_choice_url: "")

    assert completed_transaction_edition.invalid?
    assert_includes completed_transaction_edition.errors[:promotion_choice_url], "can't be blank"
  end

  test "match the schema for allowed valies in `promotion_choice`" do
    # NOTE: We don't do a full equality test here because otherwise we can
    # get locked into failing tests when we try to add or remove a value
    # On CI jenkins will use the production releases when testing against the
    # schema which won't have the changes; and we can't publish the schema
    # because it'll test against the production publisher which won't have
    # been changed.  A subset test will allow us to have some confidence
    # that we're not out of sync. We have to remember to remove values from
    # publisher and deploy them before we remove them from content schemas
    allowed_values = GovukSchemas::Schema.find(publisher_schema: 'completed_transaction')['definitions']['details']['properties']['promotion']['properties']['category']['enum']
    extra_values_in_presenter = CompletedTransactionEdition::PROMOTIONS - allowed_values
    assert extra_values_in_presenter.empty?, "CompletedTransactionEdition allows values for promotion that the schema does not.\nEdition allows: #{subject.class::PROMOTIONS.sort.inspect}\nSchema allows:  #{allowed_values.sort.inspect}\nDiff:           #{extra_values_in_presenter.sort.inspect}"
  end

  test "invalid if promotion_choice is not one of the allowed ones" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition, promotion_choice: 'cheese')

    assert completed_transaction_edition.invalid?
    assert_includes completed_transaction_edition.errors[:promotion_choice], "is not included in the list"
  end

  test "stores promotion choice and URL" do
    completed_transaction_edition = FactoryGirl.build(:completed_transaction_edition)

    completed_transaction_edition.promotion_choice = "none"
    completed_transaction_edition.save!

    assert_equal "none", completed_transaction_edition.reload.promotion_choice

    completed_transaction_edition.promotion_choice = "organ_donor"
    completed_transaction_edition.promotion_choice_url = "https://www.organdonation.nhs.uk/registration/"
    completed_transaction_edition.save!

    assert_equal "organ_donor", completed_transaction_edition.reload.promotion_choice
    assert_equal "https://www.organdonation.nhs.uk/registration/", completed_transaction_edition.promotion_choice_url

    completed_transaction_edition.promotion_choice = "register_to_vote"
    completed_transaction_edition.promotion_choice_url = "https://www.gov.uk/register-to-vote"
    completed_transaction_edition.save!

    assert_equal "register_to_vote", completed_transaction_edition.reload.promotion_choice
    assert_equal "https://www.gov.uk/register-to-vote", completed_transaction_edition.promotion_choice_url
  end
end
