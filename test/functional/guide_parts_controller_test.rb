# frozen_string_literal: true

require "test_helper"

class GuidePartsControllerTest < ActionController::TestCase
  context "adding a chapter to a guide" do
    context "when user has no editor permissions" do
      setup do
        @edition = FactoryBot.create(:guide_edition)
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "prevent a new chapter being added" do
        post :create, params: {
          edition_id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "prevent the 'add new chapter' page from being displayed" do
        get :new, params: {
          edition_id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "when user has editor permissions and edition is published" do
      setup do
        @edition = FactoryBot.create(:guide_edition, :published)
        login_as_govuk_editor
      end

      should "prevent a new chapter being added" do
        post :create, params: {
          edition_id: @edition.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end

      should "prevent the 'add new chapter' page from being displayed" do
        get :new, params: {
          edition_id: @edition.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end
    end
  end

  context "editing an existing chapter" do
    context "when user has editor permissions" do
      setup do
        @edition = FactoryBot.create(:guide_edition_with_two_parts, :draft)
        login_as_govuk_editor
      end

      should "be able to render edit page for an existing chapter" do
        get :edit, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_response :ok
        assert_select "h2", "Edit chapter"
      end

      should "be able to update an existing chapter" do
        patch :update, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save",
        }
        assert_redirected_to edit_edition_guide_part_path(@edition.id, @edition.parts.first.id)
        assert_equal "Chapter updated successfully.", flash[:success]
      end

      should "be able to update an existing chapter and redirect to edit guide page" do
        patch :update, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save and summary",
        }

        assert_redirected_to edition_path(@edition.id)
        assert_equal "Chapter updated successfully.", flash[:success]
      end

      should "allow the 'confirm destroy' page to be displayed" do
        get :confirm_destroy, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_response :ok
        assert_select "h2", "Are you sure you want to delete this chapter?"
      end

      should "allow an existing chapter to be deleted" do
        part = @edition.parts.first

        delete :destroy, params: {
          edition_id: @edition.id,
          id: part.id,
        }

        @edition.reload
        assert_redirected_to edition_path(@edition.id)
        assert_equal "Chapter deleted successfully", flash[:success]
        assert @edition.parts.exclude? part
      end
    end

    context "when user has no editor permissions" do
      setup do
        @edition = FactoryBot.create(:guide_edition_with_two_parts, :draft)
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "prevent an existing chapter being edited" do
        patch :update, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save",
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "prevent the 'edit chapter' page from being displayed" do
        get :edit, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "prevent the 'confirm destroy' page from being displayed" do
        get :confirm_destroy, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "prevent an existing chapter from being deleted" do
        part = @edition.parts.first

        delete :destroy, params: {
          edition_id: @edition.id,
          id: part.id,
        }

        @edition.reload
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        assert @edition.parts.include? part
      end

      should "show view chapter page" do
        get :show, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_response :ok
        assert_select "h2", "View chapter"
      end
    end

    context "when user has editor permissions and edition is published" do
      setup do
        @edition = FactoryBot.create(:guide_edition_with_two_parts, :published)
        login_as_govuk_editor
      end

      should "prevent an existing chapter being edited" do
        patch :update, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save",
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end

      should "prevent the 'edit chapter' page from being displayed" do
        get :edit, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end

      should "prevent the 'confirm destroy' page from being displayed" do
        get :confirm_destroy, params: {
          edition_id: @edition.id,
          id: @edition.parts.first.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end

      should "prevent an existing chapter from being deleted" do
        part = @edition.parts.first

        delete :destroy, params: {
          edition_id: @edition.id,
          id: part.id,
        }

        @edition.reload
        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
        assert @edition.parts.include? part
      end
    end
  end

  context "reordering chapters in a guide" do
    context "when user has no editor permissions" do
      setup do
        @edition = FactoryBot.create(:guide_edition)
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "prevent chapters from being reordered" do
        post :bulk_update_reorder, params: {
          edition_id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "prevent the 'reorder chapters' page from being displayed" do
        get :reorder, params: {
          edition_id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "when user has editor permissions and edition is published" do
      setup do
        @edition = FactoryBot.create(:guide_edition, :published)
        login_as_govuk_editor
      end

      should "prevent chapters from being reordered" do
        post :bulk_update_reorder, params: {
          edition_id: @edition.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end

      should "prevent the 'reorder chapters' page from being displayed" do
        get :reorder, params: {
          edition_id: @edition.id,
        }

        assert_equal "You are not allowed to perform this action in the current state.", flash[:danger]
      end
    end
  end

  context "#bulk_update_reorder" do
    setup do
      @edition = FactoryBot.create(:guide_edition_with_two_parts)
      @chapter_one = @edition.order_parts[0]
      @chapter_two = @edition.order_parts[1]

      user = FactoryBot.create(:user, :govuk_editor)
      login_as(user)
    end

    should "reorder chapters according to params input" do
      post :bulk_update_reorder, params: { edition_id: @edition.id, reordered_chapters: { @chapter_two.id => "1", @chapter_one.id => "2" } }

      assert_equal @chapter_one.reload.order, 2
      assert_equal @chapter_two.reload.order, 1
    end

    %w[scheduled_for_publishing published archived].each do |state|
      context "when state is #{state}" do
        setup do
          @edition = FactoryBot.create(:guide_edition_with_two_parts, state: state, publish_at: Time.zone.now + 1.hour)
        end

        should "redirect the user to the edition show view" do
          post :bulk_update_reorder, params: {
            edition_id: @edition.id,
            reordered_chapters: {
              @edition.parts[0].id => "2",
              @edition.parts[1].id => "1",
            },
          }

          assert_redirected_to edition_path(@edition)
        end
      end
    end
  end

  context "when 'restrict_access_by_org' feature toggle is enabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, true)
      @edition = FactoryBot.create(:guide_edition, owning_org_content_ids: %w[org-two])
      @edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, owning_org_content_ids: %w[org-two])
    end

    context "GET action: new chapter" do
      should "return a 404 when requesting the new chapter action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        get :new, params: { edition_id: @edition.id }

        assert_response :not_found
      end

      should "return a 200 when requesting the new chapter action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        get :new, params: { edition_id: @edition.id }

        assert_response :ok
      end
    end

    context "GET action: edit chapter" do
      should "return a 404 when requesting the edit chapter action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        get :edit, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        assert_response :not_found
      end

      should "return a 200 when requesting the edit chapter action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        get :edit, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        assert_response :ok
      end
    end

    context "GET action: reorder chapter" do
      should "return a 404 when requesting the reorder action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        get :reorder, params: { edition_id: @edition_with_parts.id }

        assert_response :not_found
      end

      should "return a 200 when requesting the reorder action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        get :reorder, params: { edition_id: @edition_with_parts.id }

        assert_response :ok
      end
    end

    %i[create].each do |action|
      context "POST action: '##{action}'" do
        should "return a 404 when requesting the '#{action}' action on an edition owned by a different organisation and user has departmental_editor permission" do
          login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

          post action, params: { edition_id: @edition.id }

          assert_response :not_found
        end

        should "return a 302 when requesting the '#{action}' action on an edition owned by a different organisation and user does not have departmental_editor permission" do
          login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

          post action, params: {
            edition_id: @edition.id,
            part: {
              title: "a",
              slug: "a",
            },
            save: "save",
          }

          assert_response :redirect
          @edition.reload
          assert_equal "a", @edition.parts.first.title
        end
      end
    end

    context "PATCH action: update chapter" do
      should "return a 404 when requesting the update chapter action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        patch :update, params: {
          edition_id: @edition_with_parts.id,
          id: @edition_with_parts.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save and summary",
        }

        assert_response :not_found
      end

      should "return a 302 when requesting the update chapter action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        patch :update, params: {
          edition_id: @edition_with_parts.id,
          id: @edition_with_parts.parts.first.id,
          part: {
            title: "Part2",
            slug: "a",
          },
          save: "save and summary",
        }

        assert_response :redirect
        @edition_with_parts.reload
        assert_equal "Part2", @edition_with_parts.parts.first.title
      end
    end

    context "POST action: 'bulk_update_reorder'" do
      should "return a 404 when requesting the 'bulk_update_reorder' action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        post :bulk_update_reorder, params: { edition_id: @edition_with_parts.id }

        assert_response :not_found
      end

      should "return a 302 when requesting the 'bulk_update_reorder' action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        post :bulk_update_reorder, params: {
          edition_id: @edition.id,
          reordered_chapters: {
            @edition_with_parts.parts[0].id => "2",
            @edition_with_parts.parts[1].id => "1",
          },
        }

        assert_response :redirect
      end
    end

    context "GET action: confirm_destroy" do
      should "return a 404 when requesting the confirm_destroy action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        get :confirm_destroy, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        assert_response :not_found
      end

      should "return a 200 when requesting the confirm_destroy action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

        get :confirm_destroy, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        assert_response :ok
        assert_select "h2", "Are you sure you want to delete this chapter?"
      end
    end

    context "DELETE action: delete chapter" do
      should "return a 404 when requesting the destroy chapter action on an edition owned by a different organisation and user has departmental_editor permission" do
        login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

        delete :destroy, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        assert_response :not_found
      end

      should "return a 302 when requesting the destroy chapter action on an edition owned by a different organisation and user does not have departmental_editor permission" do
        login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))
        part = @edition_with_parts.parts.first

        delete :destroy, params: { edition_id: @edition_with_parts.id, id: @edition_with_parts.parts.first.id }

        @edition_with_parts.reload
        assert_redirected_to edition_path(@edition_with_parts.id)
        assert_equal "Chapter deleted successfully", flash[:success]
        assert @edition_with_parts.parts.exclude? part
      end
    end
  end
end
