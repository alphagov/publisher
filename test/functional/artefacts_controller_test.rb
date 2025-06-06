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
      assert_redirected_to root_path
      assert_includes flash[:danger], "do not have permission"
    end
  end

  # TODO: Context '#update'
  # Replicate above?
  # Need test to ensure a non-govuk-editor cannot create an artefact
  context "#update" do
    should "allow update if govuk_editor" do
      skip
    end

    should "not allow update if no editor permissions" do
      user = FactoryBot.create(:user, name: "Non-editor")
      edition = FactoryBot.create(:edition)
      login_as(user)

      # artefact_path(edition.id)
      patch :update, params: { id: edition.artefact.id }

      # TODO: this needs to flash but stay on the page
      assert_response :redirect
      assert_redirected_to edition_path(edition.id)
      assert_includes flash[:danger], "You do not have correct editor permissions for this action."
    end
  end
end
