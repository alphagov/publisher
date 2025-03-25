require "test_helper"

class EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:restrict_access_by_org, true)
    @edition = FactoryBot.create(:edition, :fact_check)
    @welsh_edition = FactoryBot.create(:edition, :fact_check, :welsh)
    UpdateWorker.stubs(:perform_async)
    stub_events_for_all_content_ids
    stub_users_from_signon_api
  end

  context "#template_folder_for" do
    should "be able to create a view path for a given publication" do
      l = LocalTransactionEdition.new
      assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
      g = GuideEdition.new
      assert_equal "app/views/guides", @controller.template_folder_for(g)
    end
  end

  context "#index" do
    should "redirect to root" do
      get :index
      assert_response :redirect
      assert_redirected_to root_path
    end
  end

  context "#show" do
    should "return a 404 when requesting a publication that doesn't exist" do
      get :show, params: { id: "4e663834e2ba80480a0000e6" }
      assert_response :not_found
    end

    should "return a view for the requested edition" do
      get :show, params: { id: @edition.id }
      assert_response :success
      assert_not_nil assigns(:resource)
    end
  end

  context "#request_amendments_page" do
    context "user has govuk_editor permission" do
      should "render the 'Request amendments' page" do
        get :request_amendments_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/request_amendments_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :request_amendments_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#request_amendments" do
    setup do
      @edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: Time.zone.now,
      )
    end

    context "user has govuk_editor permission" do
      should "update the edition status to 'amends_needed' and save the comment" do
        post :request_amendments, params: {
          id: @edition.id,
          comment: "This is a comment",
        }

        assert_equal "2i amendments requested", flash[:success]
        @edition.reload
        assert_equal "This is a comment", @edition.latest_status_action.comment
        assert_equal "amends_needed", @edition.state
      end

      should "not update the edition state and render 'request_amendments' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        post :request_amendments, params: {
          id: @edition.id,
        }

        assert_template "secondary_nav_tabs/request_amendments_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "in_review", @edition.state
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        post :request_amendments, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#no_changes_needed_page" do
    context "user has govuk_editor permission" do
      should "render the 'No changes needed' page" do
        get :no_changes_needed_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/no_changes_needed_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :no_changes_needed_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "render the 'No changes needed' page when the edition is Welsh" do
        get :no_changes_needed_page, params: { id: @welsh_edition.id }
        assert_template "secondary_nav_tabs/no_changes_needed_page"
      end

      should "render an error message when the edition is not Welsh" do
        get :no_changes_needed_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#no_changes_needed" do
    setup do
      @edition = FactoryBot.create(
        :edition,
        state: "in_review",
        review_requested_at: Time.zone.now,
      )
    end

    context "user has govuk_editor permission" do
      should "update the edition status to 'ready' and save the comment" do
        post :no_changes_needed, params: {
          id: @edition.id,
          comment: "Perfecto!",
        }

        assert_equal "2i approved", flash[:success]
        @edition.reload
        assert_equal "Perfecto!", @edition.latest_status_action.comment
        assert_equal "ready", @edition.state
      end

      should "not update the edition state and render 'no_changes_needed' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        post :no_changes_needed, params: {
          id: @edition.id,
          amendment_comment: "This is a comment",
        }

        assert_template "secondary_nav_tabs/no_changes_needed_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "in_review", @edition.state
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        post :no_changes_needed, params: {
          id: @edition.id,
          amendment_comment: "This is a comment",
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#skip_review_page" do
    context "user has skip_review permission" do
      setup do
        user = FactoryBot.create(:user, :skip_review)
        login_as(user)
      end

      should "render the 'Skip review' page" do
        get :skip_review_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/skip_review_page"
      end
    end

    context "user does not have skip_review permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :skip_review_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#skip_review" do
    context "user is the requester and has 'skip_review' permission" do
      setup do
        requester = FactoryBot.create(:user, :skip_review, name: "Stub Requester")
        @edition = FactoryBot.create(
          :edition,
          state: "in_review",
          review_requested_at: Time.zone.now,
        )
        @edition.actions.create!(
          request_type: Action::REQUEST_REVIEW,
          requester_id: requester.id,
          created_at: Time.zone.now,
          comment: "Requesting review",
        )
        login_as(requester)
      end

      should "update the edition status to 'ready' and save the comment" do
        post :skip_review, params: {
          id: @edition.id,
          comment: "Review not needed",
        }

        assert_equal "2i review skipped", flash[:success]
        @edition.reload
        assert_equal "Review not needed", @edition.latest_status_action(:skip_review).comment
        assert_equal "ready", @edition.state
      end

      should "not update the edition state and render 'skip_review' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        post :skip_review, params: {
          id: @edition.id,
        }

        assert_template "secondary_nav_tabs/skip_review_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "in_review", @edition.state
      end
    end

    context "user is not the requester" do
      setup do
        @edition = FactoryBot.create(
          :edition,
          state: "in_review",
          review_requested_at: Time.zone.now,
        )
        @edition.actions.create!(
          request_type: Action::REQUEST_REVIEW,
          requester_id: FactoryBot.create(:user, name: "Stub Requester").id,
          created_at: Time.zone.now,
          comment: "Requesting review",
        )
        login_as(FactoryBot.create(:user, :skip_review))
      end

      should "render an error message" do
        post :skip_review, params: {
          id: @edition.id,
        }

        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have 'skip_review' permission" do
      setup do
        requester = FactoryBot.create(:user, name: "Stub Requester")
        @edition = FactoryBot.create(
          :edition,
          state: "in_review",
          review_requested_at: Time.zone.now,
        )
        @edition.actions.create!(
          request_type: Action::REQUEST_REVIEW,
          requester_id: requester.id,
          created_at: Time.zone.now,
          comment: "Requesting review",
        )
        login_as(requester)
      end

      should "render an error message" do
        post :skip_review, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#metadata" do
    should "alias to show method" do
      assert_equal EditionsController.new.method(:metadata).super_method.name, :show
    end
  end

  context "#history" do
    should "render the 'History and notes' tab of the edit page" do
      get :history, params: { id: @edition.id }
      assert_template "show"
    end
  end

  context "when 'restrict_access_by_org' feature toggle is disabled" do
    setup do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, false)
    end

    teardown do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:restrict_access_by_org, true)
    end

    %i[show metadata history related_external_links].each do |action|
      context "##{action}" do
        setup do
          @edition = FactoryBot.create(:edition, owning_org_content_ids: %w[org-two])
        end

        should "return a 200 when requesting the #{action} tab on an edition owned by a different organisation and user has departmental_editor permission" do
          login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :ok
        end

        should "return a 200 when requesting the #{action} tab on an edition owned by a different organisation and user does not have departmental_editor permission" do
          login_as(FactoryBot.create(:user, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :ok
        end
      end
    end
  end

  context "when 'restrict_access_by_org' feature toggle is enabled" do
    %i[show metadata history admin related_external_links unpublish].each do |action|
      context "##{action}" do
        setup do
          @edition = FactoryBot.create(:edition, owning_org_content_ids: %w[org-two])
        end

        should "return a 404 when requesting the #{action} tab on an edition owned by a different organisation and user has departmental_editor permission" do
          login_as(FactoryBot.create(:user, :departmental_editor, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :not_found
        end

        should "return a 200 when requesting the #{action} tab on an edition owned by a different organisation and user does not have departmental_editor permission" do
          login_as(FactoryBot.create(:user, :govuk_editor, organisation_content_id: "org-one"))

          get action, params: { id: @edition.id }

          assert_response :ok
        end
      end
    end
  end

  context "#unpublish" do
    should "redirect to edition_path when user does not have govuk-editor permission" do
      user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
      login_as(user)
      get :unpublish, params: { id: @edition.id }

      assert_redirected_to edition_path(@edition)
    end

    context "#confirm_unpublish" do
      should "redirect to edition_path when user does not have govuk-editor permission" do
        user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(user)
        get :confirm_unpublish, params: { id: @edition.id }

        assert_redirected_to edition_path(@edition)
      end

      should "render 'confirm_unpublish' template if redirect url is blank" do
        get :confirm_unpublish, params: { id: @edition.id, redirect_url: "" }

        assert_template "secondary_nav_tabs/confirm_unpublish"
      end

      should "render 'confirm_unpublish' template if redirect url is a valid url" do
        get :confirm_unpublish, params: { id: @edition.id, redirect_url: "https://www.gov.uk/redirect-to-replacement-page" }

        assert_template "secondary_nav_tabs/confirm_unpublish"
      end

      should "render show template with error message when redirect url is not valid" do
        get :confirm_unpublish, params: { id: @edition.id, redirect_url: "bob" }

        assert_select ".gem-c-error-summary__list-item", "Redirect path is invalid. Answer can not be unpublished."
        assert_template "show"
      end
    end

    context "#process_unpublish" do
      should "redirect to edition_path when user does not have govuk-editor permission" do
        user = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
        login_as(user)
        get :confirm_unpublish, params: { id: @edition.id, redirect_url: nil }

        assert_redirected_to edition_path(@edition)
      end

      should "show success message and redirect to root path when unpublished successfully with redirect url" do
        get :process_unpublish, params: { id: @edition.id, redirect_url: "https://www.gov.uk/redirect-to-replacement-page" }

        assert_equal "Content unpublished and redirected", flash[:success]
      end

      should "show success message and redirect to root path when unpublished successfully without redirect url" do
        UnpublishService.stubs(:call).returns(true)
        get :process_unpublish, params: { id: @edition.id, redirect_url: nil }

        assert_equal "Content unpublished", flash[:success]
      end

      should "show error message when unpublish is unsuccessful" do
        UnpublishService.stubs(:call).returns(nil)
        get :process_unpublish, params: { id: @edition.id, redirect_url: nil }

        assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be unpublished"
      end

      should "show error message when unpublish service returns an error" do
        UnpublishService.stubs(:call).raises(StandardError)
        get :process_unpublish, params: { id: @edition.id, redirect_url: nil }

        assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be unpublished"
      end
    end
  end

  context "#admin" do
    context "user without required permissions" do
      context "Welsh editor and non-Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        %i[admin confirm_destroy].each do |path|
          should "show permission error and redirect to edition path for #{path} path" do
            get path, params: { id: @edition.id }

            assert_redirected_to edition_path(@edition)
            assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
          end
        end
      end

      context "non-Welsh, non-govuk editor" do
        setup do
          user = FactoryBot.create(:user, name: "Stub User")
          login_as(user)
        end

        %i[admin confirm_destroy].each do |path|
          should "show permission error and redirect to edition path for #{path} path" do
            get path, params: { id: @edition.id }

            assert_redirected_to edition_path(@edition)
            assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
          end
        end
      end
    end

    context "user with required permissions" do
      context "Welsh editor and Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        %i[admin confirm_destroy].each do |path|
          should "be able to navigate successfully to #{path} path" do
            get path, params: { id: @welsh_edition.id }

            assert_response :success
          end
        end
      end

      should "be able to navigate to the admin path" do
        get :admin, params: { id: @edition.id }

        assert_response :success
      end

      context "#confirm_destroy" do
        should "be able to navigate to the confirm destroy path" do
          get :confirm_destroy, params: { id: @edition.id }

          assert_response :success
        end

        should "delete the edition from the database and display success message with redirection to root" do
          delete :destroy, params: { id: @edition.id }

          assert_equal 0, Edition.where(id: @edition.id).count
          assert_equal "Edition deleted", flash[:success]
          assert_redirected_to root_path
        end

        %i[published scheduled_for_publishing archived].each do |edition_state|
          context "edition in '#{edition_state}' state can not be deleted" do
            setup do
              @edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour)
            end

            should "redirect to edition path with error message" do
              delete :destroy, params: { id: @edition.id }

              assert_redirected_to edition_path
              assert_equal "Cannot delete a #{description(@edition)} that has ever been published.", flash[:danger]
            end
          end
        end

        should "render confirm destroy page with error if deleting from database fails" do
          Edition.any_instance.stubs(:destroy!).raises(Mongoid::Errors::MongoidError.new)

          delete :destroy, params: { id: @edition.id }

          assert_template "secondary_nav_tabs/confirm_destroy"
          assert_equal "Due to a service problem, the edition couldn't be deleted", flash[:danger]
        end
      end
    end
  end

  context "#duplicate" do
    setup do
      @answer = FactoryBot.create(:answer_edition)
      @help = FactoryBot.create(:help_page_edition)
    end

    should "redirect to the edit tab of the newly created edition and show success message when user saves successfully" do
      EditionDuplicator.any_instance.expects(:duplicate).returns(true)
      EditionDuplicator.any_instance.expects(:new_edition).returns(@help)

      post :duplicate, params: { id: @edition.id, to: "help_page" }

      assert_redirected_to edition_path(@help)
      assert_equal "New edition created", flash[:success]
    end

    should "redirect to the edit tab and show a failure message when saving the new edition fails" do
      EditionDuplicator.any_instance.expects(:duplicate).returns(false)

      post :duplicate, params: { id: @edition.id, to: "help_page" }

      assert_response :found
      assert_equal "Failed to create new edition: couldn't initialise", flash[:danger]
    end

    should "redirect to the edit tab and show a failure message when another user has already created a new edition" do
      FactoryBot.create(:edition, panopticon_id: @edition.artefact.id)

      post :duplicate, params: { id: @edition.id, to: "help_page" }

      assert_response :found
      assert_equal "Another person has created a newer edition", flash[:warning]
    end

    should "render the edit tab and show a failure message when there is a service problem" do
      EditionDuplicator.any_instance.expects(:duplicate).raises(StandardError)

      post :duplicate, params: { id: @edition.id, to: "help_page" }

      assert_template "show"
      assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be duplicated"
    end
  end

  context "#progress" do
    context "Welsh editor" do
      setup do
        login_as_welsh_editor
      end

      should "be able to skip fact checks for Welsh editions" do
        post :progress,
             params: {
               id: @welsh_edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal flash[:success], "The fact check has been skipped for this publication."
        assert_equal @welsh_edition.state, "ready"
      end

      should "not be able to skip fact checks for non-Welsh editions" do
        post :progress,
             params: {
               id: @edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "fact_check"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end
    end

    context "govuk editor" do
      setup do
        login_as_govuk_editor
      end

      should "be able to skip fact checks" do
        post :progress,
             params: {
               id: @edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal flash[:success], "The fact check has been skipped for this publication."
        assert_equal @edition.state, "ready"
      end

      should "be able to skip fact checks Welsh editions" do
        post :progress,
             params: {
               id: @welsh_edition.id,
               edition: {
                 activity: {
                   "request_type" => "skip_fact_check",
                   "comment" => "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal "ready", @welsh_edition.state
      end
    end
  end

  context "#update" do
    should "show update and success message and render show template when saved" do
      post :update, params: {
        id: @edition.id,
        edition: {
          title: "The changed title",
        },
      }

      assert_template "show"
      assert_equal "Edition updated successfully.", flash[:success]
      @edition.reload
      assert_equal "The changed title", @edition.title
    end

    should "show error message and render show template when title field is blank" do
      post :update, params: {
        id: @edition.id,
        edition: {
          title: "",
        },
      }

      assert_template "show"
      assert_select ".gem-c-error-summary__list-item", "Enter a title"
    end

    should "show error message and render show template when the edition could not be updated" do
      Edition.any_instance.stubs(:save).raises(StandardError)
      post :update, params: {
        id: @edition.id,
        edition: {
          title: "A title",
        },
      }

      assert_template "show"
      assert_select ".gem-c-error-summary__list-item", "Due to a service problem, the edition couldn't be updated"
    end

    should "call update worker with edition id when saved" do
      UpdateWorker.expects(:perform_async).with(@edition.id.to_s)

      post :update, params: {
        id: @edition.id,
        edition: {
          title: "The changed title",
        },
      }
    end
  end

  context "#edit_assignee" do
    context "user without required permissions" do
      context "Welsh editor and non-Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "show permission error and redirect to edition path" do
          get :edit_assignee, params: { id: @edition.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end

      context "non-Welsh, non-govuk editor" do
        setup do
          user = FactoryBot.create(:user, name: "Stub User")
          login_as(user)
        end

        should "show permission error and redirect to edition path" do
          get :edit_assignee, params: { id: @edition.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end
    end

    context "user with required permissions" do
      context "Welsh editor and Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "be able to navigate successfully to edit assignee path" do
          get :edit_assignee, params: { id: @welsh_edition.id }

          assert_response :success
        end
      end

      should "be able to navigate to the edit assignee path" do
        get :edit_assignee, params: { id: @edition.id }

        assert_response :success
      end

      %i[published scheduled_for_publishing archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          setup do
            @edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour)
          end

          should "redirect to edition path with error message" do
            get :edit_assignee, params: { id: @edition.id }

            assert_redirected_to edition_path
            assert_equal "Cannot edit the assignee of an edition that has been published.", flash[:danger]
          end
        end
      end
    end
  end

  context "#update_assignee" do
    context "user without required permissions" do
      context "Welsh editor and non-Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "show permission error and redirect to edition path" do
          patch :update_assignee, params: { id: @edition.id, assignee_id: @user.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end

      context "non-Welsh, non-govuk editor" do
        setup do
          user = FactoryBot.create(:user, name: "Stub User")
          login_as(user)
        end

        should "show permission error and redirect to edition path" do
          patch :update_assignee, params: { id: @edition.id, assignee_id: @user.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end
    end

    context "user with required permissions" do
      context "Welsh editor and Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "be able to successfully update assignee" do
          patch :update_assignee, params: { id: @welsh_edition.id, assignee_id: @user.id }

          assert_redirected_to edition_path(@welsh_edition.id)
        end
      end

      should "be able to successfully update assignee" do
        patch :update_assignee, params: { id: @edition.id, assignee_id: @user.id }

        assert_redirected_to edition_path(@edition.id)
      end

      should "update the assignee" do
        new_assignee = FactoryBot.create(:user, :govuk_editor, name: "Updated Assignee")
        patch :update_assignee, params: { id: @edition.id, assignee_id: new_assignee.id }

        @edition.reload
        assert_equal "Updated Assignee", @edition.assignee
      end

      should "be able to unassign the current assignee" do
        patch :update_assignee, params: { id: @edition.id, assignee_id: "none" }

        @edition.reload
        assert_nil @edition.assignee
        assert_nil @edition.assigned_to_id
      end

      %i[published scheduled_for_publishing archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          setup do
            @edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour)
          end

          should "redirect to edition path with error message" do
            get :edit_assignee, params: { id: @edition.id, assignee_id: @user.id }

            assert_redirected_to edition_path
            assert_equal "Cannot edit the assignee of an edition that has been published.", flash[:danger]
          end
        end
      end

      should "show error when database save fails" do
        new_assignee = FactoryBot.create(:user, :govuk_editor, name: "Updated Assignee")
        User.any_instance.stubs(:assign).raises(StandardError)

        patch :update_assignee, params: { id: @edition.id, assignee_id: new_assignee.id }

        assert_template "secondary_nav_tabs/_edit_assignee"
        assert_equal "Due to a service problem, the assigned person couldn't be saved", flash[:danger]
      end

      should "show error when new assignee does not have editor permission" do
        new_assignee = FactoryBot.create(:user, name: "Stub User")
        patch :update_assignee, params: { id: @edition.id, assignee_id: new_assignee.id }

        assert_template "secondary_nav_tabs/_edit_assignee"
        assert_equal "Chosen assignee does not have correct editor permissions.", flash[:danger]
      end

      should "show error when no assignee option is selected" do
        patch :update_assignee, params: { id: @edition.id }

        assert_template "secondary_nav_tabs/_edit_assignee"
        assert_equal "Please select a person to assign, or 'None' to unassign the currently assigned person.", flash[:danger]
      end

      should "show error when a non-existent assignee ID is provided" do
        patch :update_assignee, params: { id: @edition.id, assignee_id: "non-existent ID" }

        assert_template "secondary_nav_tabs/_edit_assignee"
        assert_equal "Due to a service problem, the assigned person couldn't be saved", flash[:danger]
      end
    end
  end

  context "#update_related_external_links" do
    should "display an error message when the title is blank" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "", url: "http://foo-bar.com", _destroy: false }],
        },
      }

      assert_equal "External links is invalid", flash[:danger]
    end

    should "display an error message when the url is blank" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "foo", url: "", _destroy: false }],
        },
      }

      assert_equal "External links is invalid", flash[:danger]
    end

    should "display an error message when the url is invalid" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "foo", url: "an-invalid-url", _destroy: false }],
        },
      }

      assert_equal "External links is invalid", flash[:danger]
    end

    should "update related external links and display a success message when successfully saved" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "foo", url: "https://foo-bar.com", _destroy: false }],
        },
      }

      assert_equal "Related links updated.", flash[:success]
      assert_equal "foo", @edition.artefact.external_links[0].title
      assert_equal "https://foo-bar.com", @edition.artefact.external_links[0].url
    end

    should "display an error message when there are no external links to save" do
      patch :update_related_external_links, params: {
        id: @edition.id,
      }

      assert_equal "There aren't any external related links yet", flash[:danger]
    end
  end

  context "#diff" do
    should "render the compare editions page" do
      edition_one = FactoryBot.create(:edition, :published)
      edition_two = FactoryBot.create(:edition, :published, panopticon_id: edition_one.panopticon_id)

      get :diff, params: { id: edition_two.id }

      assert_template "diff"
    end
  end

private

  def description(edition)
    edition.format.underscore.humanize.downcase
  end
end
