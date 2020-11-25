require "test_helper"

class ArtefactsControllerTest < ActionController::TestCase
  context "#new" do
    should "allow creation if govuk_editor" do
      login_as_govuk_editor

      get :new

      assert_response :ok
    end

    should "not allow creation if welsh_editor" do
      login_as_welsh_editor

      get :new

      assert_response :redirect
      assert_redirected_to controller: "root", action: "index"
      assert_includes flash[:danger], "do not have permission"
    end
  end
end
