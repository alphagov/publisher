require 'test_helper'

class Admin::PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  test "when saving publication fails we show a page" do
    panopticon_id = 2357
    assert WholeEdition.where(panopticon_id: panopticon_id).first.nil?

    panopticon_has_metadata(
      "id" => panopticon_id,
      "kind" => "local_transaction"
    )
    get :show, :id => 2357
    assert WholeEdition.where(panopticon_id: panopticon_id).first.nil?
    assert_response :success
  end
end
