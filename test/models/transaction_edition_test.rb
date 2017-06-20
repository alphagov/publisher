require 'test_helper'

class TransactionEditionTest < ActiveSupport::TestCase

  setup do
    @artefact = FactoryGirl.create(:artefact)
  end

  context 'Department analytics profiles' do
    should "only allow valid Google Analytics profiles" do
      transaction = FactoryGirl.create(:transaction_edition, panopticon_id: @artefact.id)

      ['invalid', 'ua-12345', 'UA-1234A-1'].each do |id|
        transaction.department_analytics_profile = id
        refute transaction.valid?
      end

      ['ua-123456-1', 'UA-00-10'].each do |id|
        transaction.department_analytics_profile = id
        assert transaction.valid?
      end
    end
  end

  context "indexable_content" do
    should "include the introduction without markup" do
      transaction = FactoryGirl.create(:transaction_edition, introduction: "## introduction", more_information: "", panopticon_id: @artefact.id)
      assert_equal "introduction", transaction.indexable_content
    end

    should "include the more_information without markup" do
      transaction = FactoryGirl.create(:transaction_edition, more_information: "## more info", introduction: "", panopticon_id: @artefact.id)
      assert_equal "more info", transaction.indexable_content
    end
  end
end
