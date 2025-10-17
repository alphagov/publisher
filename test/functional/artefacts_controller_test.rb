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
      assert_includes flash[:danger], "You do not have permission to see this page."
    end

    should "not allow creation if no permissions" do
      user = FactoryBot.create(:user, name: "Non-editor")
      login_as(user)

      get :new

      assert_response :redirect
      assert_redirected_to root_path
      assert_includes flash[:danger], "You do not have permission to see this page."
    end
  end

  context "#update" do
    should "allow update if govuk_editor" do
      edition = FactoryBot.create(:simple_smart_answer_edition)
      login_as_govuk_editor

      patch :update, params: {
        id: edition.artefact.id,
        artefact: {
          id: edition.artefact.id,
          slug: edition.artefact.slug,
          language: "en",
        },
      }

      assert_response :redirect
      assert_redirected_to metadata_edition_path(edition.id)
      assert_equal "Metadata has successfully updated", flash[:success]
    end

    should "not allow update even if welsh_editor and Welsh edition" do
      welsh_edition = FactoryBot.create(:simple_smart_answer_edition, :fact_check, :welsh)
      login_as_welsh_editor

      patch :update, params: { id: welsh_edition.artefact.id }

      assert_response :redirect
      assert_redirected_to metadata_edition_path(welsh_edition.id)
      assert_includes flash[:danger], "You do not have permissions to update this page"
    end

    should "not allow update if no editor permissions" do
      user = FactoryBot.create(:user, name: "Non-editor")
      edition = FactoryBot.create(:simple_smart_answer_edition)
      login_as(user)

      patch :update, params: { id: edition.artefact.id }

      assert_response :redirect
      assert_redirected_to metadata_edition_path(edition.id)
      assert_includes flash[:danger], "You do not have permissions to update this page"
    end
  end
end
