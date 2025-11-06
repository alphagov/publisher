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

  context "when 'restrict_access_by_org' feature toggle is enabled" do
    %i[new].each do |action|
      context "GET action: '##{action}'" do
        setup do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:restrict_access_by_org, true)
          @edition = FactoryBot.create(:guide_edition, owning_org_content_ids: %w[org-two])
        end

        should "return a 404 when requesting the '#{action}' action on an edition owned by a different organisation and user has departmental_editor permission" do
          login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

          get action, params: { edition_id: @edition.id }

          assert_response :not_found
        end

        should "return a 200 when requesting the '#{action}' action on an edition owned by a different organisation and user does not have departmental_editor permission" do
          login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

          get action, params: { edition_id: @edition.id }

          assert_response :ok
        end
      end
    end

    %i[create].each do |action|
      context "POST action: '##{action}'" do
        setup do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:restrict_access_by_org, true)
          @edition = FactoryBot.create(:guide_edition, owning_org_content_ids: %w[org-two])
        end

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
        end
      end
    end
  end
end
