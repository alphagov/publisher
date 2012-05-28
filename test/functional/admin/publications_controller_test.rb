require 'test_helper'

class Admin::PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  test "requesting a panopticon_id should redirect to the latest edition" do
    panopticon_id = 2357
    FactoryGirl.create(:edition, :panopticon_id => panopticon_id, :state => 'archived', :version_number => 1)
    FactoryGirl.create(:edition, :panopticon_id => panopticon_id, :state => 'published', :version_number => 2)
    latest_edition = FactoryGirl.create(:edition, :panopticon_id => panopticon_id, :state => 'draft', :version_number => 3)

    panopticon_has_metadata(
      "id" => panopticon_id,
      "kind" => "answer"
    )
    get :show, :id => panopticon_id

    assert_redirected_to(:controller => 'editions', :action => 'show', :id => latest_edition.id)
  end

  test "when saving publication fails we show a page" do
    panopticon_id = 2357
    assert Edition.where(panopticon_id: panopticon_id).first.nil?

    panopticon_has_metadata(
      "id" => panopticon_id,
      "kind" => "local_transaction"
    )
    get :show, :id => 2357
    assert Edition.where(panopticon_id: panopticon_id).first.nil?
    assert_response :success
  end
end
