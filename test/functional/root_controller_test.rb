require "test_helper"

class RootControllerTest < ActionController::TestCase
  setup do
    @users = FactoryBot.create_list(:user, 3)
    login_as_stub_user
    session[:user_filter] = @users[0].uid

    @guide = FactoryBot.create(:guide_edition, state: "draft")
  end

  test "it returns a 404 for an unknown list" do
    get :index, params: { list: "draFts" }
    assert response.not_found?
  end

  # Most values of the list parameter match a scope on the Edition
  # model, but some don't and we want to test that we allow those
  # through correctly
  test "it supports lists that don't match a model scope" do
    get :index, params: { list: "drafts" }
    assert response.ok?
  end

  test "should strip leading/trailing whitespace from string_filter" do
    @guide.update!(title: "Stuff")
    get(
      :index,
      params: {
        list: "drafts",
        user_filter: "all",
        string_filter: " stuff",
      },
    )
    assert_select "td.title", /Stuff/i
  end

  test "should strip excess interstitial whitespace from string_filter" do
    @guide.update!(title: "Stuff and things")
    get(
      :index,
      params: {
        list: "drafts",
        user_filter: "all",
        string_filter: "stuff   and things",
      },
    )
    assert_select "td.title", /Stuff and things/i
  end

  test "should search in slug with string_filter" do
    @guide.update!(title: "Stuff")
    @guide.update!(slug: "electric-banana")
    get(
      :index,
      params: {
        list: "drafts",
        user_filter: "all",
        string_filter: "electric-banana",
      },
    )
    assert_select "td.title", /Stuff/i
  end
end
