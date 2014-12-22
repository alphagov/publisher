require 'test_helper'

class DowntimesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  test "should list all published transaction editions" do
    unpublished_transaction_edition = FactoryGirl.create(:transaction_edition)
    transaction_editions = FactoryGirl.create_list(:transaction_edition, 2, :published)

    get :index

    assert_response :ok
    assert_select 'h4.publication-table-title', { count: 0, text: unpublished_transaction_edition.title }
    transaction_editions.each do |edition|
      assert_select 'h4.publication-table-title', { text: edition.title }
    end
  end
end
