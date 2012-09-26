require 'test_helper'

class Admin::RootControllerTest < ActionController::TestCase
  setup do
    @users = FactoryGirl.create_list(:user, 3)
    login_as_stub_user
    session[:user_filter] = @users[0].uid

    @guide = FactoryGirl.create(:guide_edition, state: 'draft')
  end

  test "it returns a 404 for an unknown list" do
    get :index, list: 'draFts'
    assert response.not_found?
  end

  test "it goes to the right state when a with parameter is given" do
    get :index, with: @guide.id
    assert_equal "drafts", assigns[:list]
  end

  test "it overrides the user filter with a 'with' parameter" do
    get :index, with: @guide.id
    assert_equal "all", assigns[:user_filter]
    # Also check the session isn't affected
    assert_equal @users[0].uid, session[:user_filter]
  end

  test "it only overrides the user filter when necessary" do
    @guide.assigned_to = @users[0]
    @guide.save!

    get :index, with: @guide.id
    assert_equal @users[0].uid, assigns[:user_filter]
  end

  test "it jumps to the correct page" do
    FactoryGirl.create_list(:guide_edition, 100)
    @guide = GuideEdition.order_by(['updated_at', 'desc'])[59]
    get :index, with: @guide.id.to_s
    assert_equal 3, assigns[:presenter].draft.current_page
  end

  test "it works when going to a fact check edition" do
    # Fact check is one of the states that has different names as a list filter
    # ('out_for_fact_check') and as a state ('fact_check')
    FactoryGirl.create_list(:guide_edition, 60, state: 'fact_check')
    @guide = GuideEdition.order_by(['updated_at', 'desc'])[25]
    get :index, with: @guide.id.to_s
    assert_equal 2, assigns[:presenter].fact_check.current_page
  end

end
