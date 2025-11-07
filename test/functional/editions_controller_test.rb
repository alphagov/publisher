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
    stub_holidays_used_by_fact_check
  end

  context "#template_folder_for" do
    should "be able to create a view path for a given publication" do
      l = FactoryBot.build(:local_transaction_edition)
      assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
      g = FactoryBot.build(:guide_edition)
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
      get :show, params: { id: "104" }
      assert_response :not_found
    end

    should "return a view for the requested edition" do
      get :show, params: { id: @edition.id }
      assert_response :success
      assert_not_nil assigns(:resource)
    end
  end

  context "#resend_fact_check_email_page" do
    context "user has govuk_editor permission" do
      should "render the 'Resend fact check email' page" do
        FactoryBot.create(
          :action,
          requester: @govuk_editor,
          request_type: Action::SEND_FACT_CHECK,
          edition: @edition,
          email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
          customised_message: "The customised message",
        )

        get :resend_fact_check_email_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/resend_fact_check_email_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :resend_fact_check_email_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#resend_fact_check_email" do
    %i[drafts in_review amends_needed fact_check_received ready scheduled published archived].each do |edition_state|
      context "edition is not in a valid state to resend fact check email" do
        setup do
          @edition = FactoryBot.create(:answer_edition, state: edition_state)
          FactoryBot.create(
            :action,
            requester: @govuk_editor,
            request_type: Action::SEND_FACT_CHECK,
            edition: @edition,
            email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
            customised_message: "The customised message",
          )
        end

        should "render an error" do
          patch :resend_fact_check_email, params: {
            id: @edition.id,
          }

          assert_equal "Edition is not in a state where fact check emails can be re-sent", flash[:danger]

          @edition.reload
          assert_equal edition_state.to_s, @edition.state
        end
      end
    end

    context "user has govuk_editor permission" do
      setup do
        @edition = FactoryBot.create(:answer_edition, state: "fact_check")
        FactoryBot.create(
          :action,
          requester: @govuk_editor,
          request_type: Action::SEND_FACT_CHECK,
          edition: @edition,
          email_addresses: "fact-checker-one@example.com, fact-checker-two@example.com",
          customised_message: "The customised message",
        )
      end

      should "retain the edition status as 'fact_check' and save the action in 'History & notes'" do
        patch :resend_fact_check_email, params: {
          id: @edition.id,
        }

        assert_equal "Fact check email re-sent", flash[:success]
        @edition.reload
        assert_equal "fact-checker-one@example.com, fact-checker-two@example.com", @edition.latest_status_action.email_addresses
        assert_equal "The customised message", @edition.latest_status_action.customised_message
        assert_equal "fact_check", @edition.state
      end

      should "render 'resend_fact_check_email_page' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        patch :resend_fact_check_email, params: {
          id: @edition.id,
        }

        assert_template "secondary_nav_tabs/resend_fact_check_email_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "fact_check", @edition.state
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        patch :resend_fact_check_email, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#add_edition_note" do
    context "user has govuk_editor permission" do
      should "render the 'Add Edition Note' page" do
        get :add_edition_note, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/add_edition_note"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :add_edition_note, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#update_important_note" do
    context "user has govuk_editor permission" do
      should "render the 'Update Important Note' page" do
        get :update_important_note, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/update_important_note"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :update_important_note, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
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
    context "edition is not in a valid state to request amendments" do
      setup do
        @edition = FactoryBot.create(:edition, state: "draft")
      end

      should "not update the edition state and render an error" do
        post :request_amendments, params: {
          id: @edition.id,
        }

        assert_equal "Edition is not in a state where amendments can be requested", flash[:danger]

        @edition.reload
        assert_equal "draft", @edition.state
      end
    end

    # NOTE: Eventually this list will also contain the 'fact_check_received' state
    %i[in_review ready fact_check].each do |edition_state|
      context "edition is in a valid state to request amendments" do
        setup do
          @edition = FactoryBot.create(
            :edition,
            state: edition_state,
            review_requested_at: Time.zone.now,
          )
        end

        context "user has govuk_editor permission" do
          should "update the edition status to 'amends_needed' and save the comment" do
            post :request_amendments, params: {
              id: @edition.id,
              comment: "This is a comment",
            }

            assert_equal "Amendments requested", flash[:success]
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
            assert_equal edition_state.to_s, @edition.state
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

    context "edition is not in a valid state to approve review (no changes needed)" do
      setup do
        @edition = FactoryBot.create(:edition, state: "draft")
      end

      should "not update the edition state and render an error" do
        post :no_changes_needed, params: {
          id: @edition.id,
        }

        assert_equal "Edition is not in a state where a review can be approved", flash[:danger]

        @edition.reload
        assert_equal "draft", @edition.state
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

      context "edition is not in a valid state to skip review" do
        should "not update the edition state and render an error" do
          @edition = FactoryBot.create(:edition, state: "draft")
          post :skip_review, params: {
            id: @edition.id,
          }

          assert_equal "Edition is not in a state where review can be skipped", flash[:danger]

          @edition.reload
          assert_equal "draft", @edition.state
        end
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

  context "#send_to_2i_page" do
    context "user has govuk_editor permission" do
      should "render the 'Send to 2i' page" do
        get :send_to_2i_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/send_to_2i_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :send_to_2i_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "render the 'Send to 2i' page when the edition is Welsh" do
        get :send_to_2i_page, params: { id: @welsh_edition.id }
        assert_template "secondary_nav_tabs/send_to_2i_page"
      end

      should "render an error message when the edition is not Welsh" do
        get :send_to_2i_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#send_to_2i" do
    setup do
      @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
      @edition = FactoryBot.create(:edition, state: "draft")
      login_as(@requester)
    end

    context "user has govuk_editor permission" do
      should "update the edition status to 'in_review' and save the comment" do
        post :send_to_2i, params: {
          id: @edition.id,
          comment: "Please review this",
        }

        assert_equal "Sent to 2i", flash[:success]
        @edition.reload
        assert_equal "in_review", @edition.state
        assert_equal "Please review this", @edition.latest_status_action.comment
        assert_equal @requester.id, @edition.latest_status_action.requester_id
      end

      should "not update the edition state and render 'send_to_2i' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        post :send_to_2i, params: {
          id: @edition.id,
        }

        assert_template "secondary_nav_tabs/send_to_2i_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "draft", @edition.state
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        post :send_to_2i, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "edition is not in a valid state to be sent to 2i" do
      setup do
        @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
        @edition = FactoryBot.create(:edition, state: "ready")
      end

      should "not update the edition state and render 'send_to_2i' template with an error" do
        post :send_to_2i, params: {
          id: @edition.id,
        }

        assert_equal "Edition is not in a state where it can be sent to 2i", flash[:danger]

        @edition.reload
        assert_equal "ready", @edition.state
      end
    end
  end

  context "#send_to_fact_check_page" do
    context "user has govuk_editor permission" do
      should "render the 'Send to Fact check' page" do
        edition = FactoryBot.create(:edition, :ready)

        get :send_to_fact_check_page, params: { id: edition.id }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
      end
    end

    context "user does not have govuk_editor permission" do
      should "render an error message" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :send_to_fact_check_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "render the 'Send to Fact check' page when the edition is Welsh" do
        welsh_edition = FactoryBot.create(:edition, :ready, :welsh)

        get :send_to_fact_check_page, params: { id: welsh_edition.id }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
      end

      should "render an error message when the edition is not Welsh" do
        get :send_to_fact_check_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "edition is not in a valid state to be sent to fact check" do
      %i[draft in_review amends_needed fact_check scheduled_for_publishing published archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          should "redirect to edition path with error message" do
            edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour, review_requested_at: 1.hour.ago)

            get :send_to_fact_check_page, params: { id: edition.id }

            assert_redirected_to edition_path
            assert_equal "Edition is not in a state where it can be sent to fact check", flash[:danger]
          end
        end
      end
    end
  end

  context "#send_to_fact_check" do
    context "user is not a govuk_editor or welsh editor" do
      should "render an error message" do
        user = FactoryBot.create(:user)
        login_as(user)

        post :send_to_fact_check, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user is a welsh editor but it is not a welsh edition" do
      should "render an error message" do
        login_as_welsh_editor

        post :send_to_fact_check, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "edition is not in a valid state to be sent to fact check" do
      %i[draft in_review amends_needed fact_check scheduled_for_publishing published archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          should "redirect to edition path with error message" do
            edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour, review_requested_at: 1.hour.ago)

            post :send_to_fact_check, params: {
              id: edition.id,
            }

            assert_redirected_to edition_path
            assert_equal "Edition is not in a state where it can be sent to fact check", flash[:danger]
          end
        end
      end
    end

    context "user has govuk_editor permission" do
      ["test@test.com", "test1@test.com, test2@test.com"].each do |email_addresses|
        context "using email address(es) '#{email_addresses}'" do
          should "update the edition status to 'fact_check', generate the comment and save the user input" do
            edition = FactoryBot.create(:edition, :ready)

            post :send_to_fact_check, params: {
              id: edition.id,
              email_addresses: email_addresses,
              customised_message: "Please fact check this",
            }

            assert_equal "Sent to fact check", flash[:success]
            edition.reload
            assert_equal "fact_check", edition.state
            assert_equal "Sent to fact check", edition.latest_status_action.comment
            assert_equal email_addresses, edition.latest_status_action.email_addresses
            assert_equal "Please fact check this", edition.latest_status_action.customised_message
          end
        end
      end

      should "not update the edition state and render an error message when no email addresses are provided" do
        edition = FactoryBot.create(:edition, :ready)

        post :send_to_fact_check, params: {
          id: edition.id,
          email_addresses: "",
          customised_message: "Please fact check this",
        }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
        assert_equal "Enter email addresses and/or customised message", flash[:danger]
        edition.reload
        assert_equal "ready", edition.state
      end

      should "not update the edition state and render an error message when email address is invalid" do
        edition = FactoryBot.create(:edition, :ready)

        post :send_to_fact_check, params: {
          id: edition.id,
          email_addresses: "user1@example.com, another-user AT example DOT com",
          customised_message: "Please fact check this",
        }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
        assert_equal "Enter email addresses and/or customised message", flash[:danger]
        edition.reload
        assert_equal "ready", edition.state
      end

      should "not update the edition state and render an error message when customised message is empty" do
        edition = FactoryBot.create(:edition, :ready)

        post :send_to_fact_check, params: {
          id: edition.id,
          email_addresses: "user1@example.com",
          customised_message: "",
        }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
        assert_equal "Enter email addresses and/or customised message", flash[:danger]
        edition.reload
        assert_equal "ready", edition.state
      end

      should "not update the edition state and render an error message when the edition progression is false" do
        EditionProgressor.any_instance.stubs(:progress).returns(false)

        edition = FactoryBot.create(:edition, :ready)
        post :send_to_fact_check, params: {
          id: edition.id,
          email_addresses: "test@test.com",
          customised_message: "Please fact check this",
        }

        assert_template "secondary_nav_tabs/send_to_fact_check_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        edition.reload
        assert_equal "ready", edition.state
      end

      should "not update the edition state render an error message when a system error occurs" do
        EditionProgressor.any_instance.stubs(:progress).raises(StandardError)

        edition = FactoryBot.create(:edition, :ready)
        post :send_to_fact_check, params: {
          id: edition.id,
          email_addresses: "test@test.com",
          customised_message: "Please fact check this",
        }
        assert_template "secondary_nav_tabs/send_to_fact_check_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        edition.reload
        assert_equal "ready", edition.state
      end
    end
  end

  context "#schedule_page" do
    setup do
      @ready_edition = FactoryBot.create(:answer_edition, :ready)
    end

    context "user has govuk_editor permission" do
      should "be able to navigate successfully to schedule page path" do
        get :schedule_page, params: { id: @ready_edition.id }

        assert_response :success
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "show permission error and redirect to edition path" do
        get :schedule_page, params: { id: @ready_edition.id }

        assert_redirected_to edition_path(@ready_edition)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "show permission error and redirect to edition path" do
        get :schedule_page, params: { id: @ready_edition.id }

        assert_redirected_to edition_path(@ready_edition)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "be able to navigate successfully to schedule page path" do
        @welsh_ready_edition = FactoryBot.create(:answer_edition, :ready, :welsh)
        get :schedule_page, params: { id: @welsh_ready_edition.id }

        assert_response :success
      end
    end

    context "edition is not in 'ready' state" do
      %i[draft in_review amends_needed fact_check fact_check_received scheduled_for_publishing published archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          setup do
            @edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour, review_requested_at: 1.hour.ago)
          end

          should "redirect to edition path with error message" do
            get :schedule_page, params: { id: @edition.id }

            assert_redirected_to edition_path
            assert_equal "Cannot schedule an edition that is not ready.", flash[:danger]
          end
        end
      end
    end
  end

  context "#schedule" do
    context "Edition is not in 'Ready' state" do
      setup do
        @edition = FactoryBot.create(:answer_edition, state: "draft")
      end

      should "not update the edition status and should show a warning message" do
        post :schedule, params: {
          id: @edition.id,
        }

        assert_equal "Edition is not in a state where it can be scheduled for publishing", flash[:danger]
        assert_template "secondary_nav_tabs/schedule_page"
        @edition.reload
        assert_equal "draft", @edition.state
      end
    end

    context "Edition is in 'Ready' state" do
      setup do
        @edition = FactoryBot.create(:answer_edition, state: "ready")
        @past_date = 1.day.ago
        @future_date = 1.day.from_now
      end

      context "user has govuk_editor permission" do
        setup do
          @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
          login_as(@requester)
        end

        should "show an error if any date/time fields are left blank" do
          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_1i: nil,
            publish_at_2i: @future_date.month,
            publish_at_3i: @future_date.day,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_1i: @future_date.year,
            publish_at_2i: nil,
            publish_at_3i: @future_date.day,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_1i: @future_date.year,
            publish_at_2i: @future_date.month,
            publish_at_3i: nil,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_1i: @future_date.year,
            publish_at_2i: @future_date.month,
            publish_at_3i: @future_date.day,
            publish_at_4i: nil,
            publish_at_5i: @future_date.min,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_1i: @future_date.year,
            publish_at_2i: @future_date.month,
            publish_at_3i: @future_date.day,
            publish_at_4i: @future_date.hour,
            publish_at_5i: nil,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]
        end

        should "show an error if the publish at date is in the past" do
          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_3i: @past_date.day,
            publish_at_2i: @past_date.month,
            publish_at_1i: @past_date.year,
            publish_at_4i: @past_date.hour,
            publish_at_5i: @past_date.min,
          }

          assert_equal "Select a future time and/or date to schedule publication.", flash[:danger]
        end

        should "update the edition state to 'scheduled_for_publishing' and save the comment" do
          ScheduledPublisher.stubs(:enqueue)

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_3i: @future_date.day,
            publish_at_2i: @future_date.month,
            publish_at_1i: @future_date.year,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_equal "Scheduled to publish at #{@future_date.to_fs(:govuk_date)}", flash[:success]
          @edition.reload
          assert_equal "scheduled_for_publishing", @edition.state
          assert_equal "Scheduling for publish", @edition.latest_status_action.comment
          assert_equal @requester.id, @edition.latest_status_action.requester_id
        end

        should "not update the edition state and render 'schedule_page' template with an error when an error occurs" do
          EditionProgressor.any_instance.expects(:progress).returns(false)

          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_3i: @future_date.day,
            publish_at_2i: @future_date.month,
            publish_at_1i: @future_date.year,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_template "secondary_nav_tabs/schedule_page"
          assert_equal "Due to a service problem, the request could not be made", flash[:danger]
          @edition.reload
          assert_equal "ready", @edition.state
        end
      end

      context "user does not have govuk_editor or welsh_editor permissions" do
        setup do
          user = FactoryBot.create(:user)
          login_as(user)
        end

        should "render an error message" do
          post :schedule, params: {
            id: @edition.id,
            comment: "Scheduling for publish",
            publish_at_3i: @future_date.day,
            publish_at_2i: @future_date.month,
            publish_at_1i: @future_date.year,
            publish_at_4i: @future_date.hour,
            publish_at_5i: @future_date.min,
          }

          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end
    end
  end

  context "#send_to_publish_page" do
    context "user has govuk_editor permission" do
      should "render the 'Publish now' page" do
        get :send_to_publish_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/send_to_publish_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :send_to_publish_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "render the 'Publish now' page when the edition is Welsh" do
        get :send_to_publish_page, params: { id: @welsh_edition.id }
        assert_template "secondary_nav_tabs/send_to_publish_page"
      end

      should "render an error message when the edition is not Welsh" do
        get :send_to_publish_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#send_to_publish" do
    context "edition is in 'scheduled_for_publishing' state" do
      setup do
        @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
        @edition = FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour)
        login_as(@requester)
      end

      context "user has govuk_editor permission" do
        setup do
          ScheduledPublisher.stubs(:cancel_scheduled_publishing)
          PublishWorker.stubs(:perform_async)
        end

        should "update the edition status to 'published' and save the comment" do
          post :send_to_publish, params: {
            id: @edition.id,
            comment: "Publishing with immediate effect",
          }

          assert_equal "Published", flash[:success]
          @edition.reload
          assert_equal "published", @edition.state
          assert_equal "Publishing with immediate effect", @edition.latest_status_action.comment
          assert_equal @requester.id, @edition.latest_status_action.requester_id
        end

        should "not update the edition state and render 'send_to_publish' template with an error when an error occurs" do
          EditionProgressor.any_instance.expects(:progress).returns(false)

          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_template "secondary_nav_tabs/send_to_publish_page"
          assert_equal "Due to a service problem, the request could not be made", flash[:danger]
          @edition.reload
          assert_equal "scheduled_for_publishing", @edition.state
        end

        should "notify the publishing API to publish the edition" do
          PublishWorker.expects(:perform_async).with(@edition.id.to_s)

          post :send_to_publish, params: {
            id: @edition.id,
          }
        end
      end

      context "user does not have govuk_editor permission" do
        setup do
          user = FactoryBot.create(:user)
          login_as(user)
        end

        should "render an error message" do
          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end

      context "edition is not in a valid state to be published" do
        setup do
          @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
          @edition = FactoryBot.create(:edition, state: "draft")
        end

        should "not update the edition state and render 'send_to_publish' template with an error" do
          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_equal "Edition is not in a state where it can be published", flash[:danger]

          assert_template "secondary_nav_tabs/send_to_publish_page"
          @edition.reload
          assert_equal "draft", @edition.state
        end
      end
    end

    context "edition is in 'ready' state" do
      setup do
        @edition = FactoryBot.create(:edition, state: "ready")
        login_as_stub_user
      end

      context "user has govuk_editor permission" do
        setup do
          PublishWorker.stubs(:perform_async)
        end

        should "update the edition status to 'published' and save the comment" do
          post :send_to_publish, params: {
            id: @edition.id,
            comment: "Publishing this ready edition",
          }

          assert_equal "Published", flash[:success]
          @edition.reload
          assert_equal "published", @edition.state
          assert_equal "Publishing this ready edition", @edition.latest_status_action.comment
          assert_equal @user.id, @edition.latest_status_action.requester_id
        end

        should "not update the edition state and render 'send_to_publish' template with an error when an error occurs" do
          EditionProgressor.any_instance.expects(:progress).returns(false)

          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_template "secondary_nav_tabs/send_to_publish_page"
          assert_equal "Due to a service problem, the request could not be made", flash[:danger]
          @edition.reload
          assert_equal "ready", @edition.state
        end

        should "notify the publishing API to publish the edition" do
          PublishWorker.expects(:perform_async).with(@edition.id.to_s)

          post :send_to_publish, params: {
            id: @edition.id,
          }
        end
      end

      context "user does not have govuk_editor permissions" do
        setup do
          user = FactoryBot.create(:user)
          login_as(user)
        end

        should "render an error message" do
          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end

      context "edition is not in a valid state to be published" do
        setup do
          @edition = FactoryBot.create(:edition, state: "draft")
        end

        should "not update the edition state and render 'send_to_publish' template with an error" do
          post :send_to_publish, params: {
            id: @edition.id,
          }

          assert_equal "Edition is not in a state where it can be published", flash[:danger]

          assert_template "secondary_nav_tabs/send_to_publish_page"
          @edition.reload
          assert_equal "draft", @edition.state
        end
      end
    end
  end

  context "#cancel_scheduled_publishing_page" do
    context "user has govuk_editor permission" do
      should "render the 'Cancel scheduled publishing' page" do
        get :cancel_scheduled_publishing_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/cancel_scheduled_publishing_page"
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :cancel_scheduled_publishing_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "user has welsh_editor permission" do
      setup do
        login_as_welsh_editor
      end

      should "render the 'Cancel scheduled publishing' page when the edition is welsh" do
        get :cancel_scheduled_publishing_page, params: { id: @welsh_edition.id }
        assert_template "secondary_nav_tabs/cancel_scheduled_publishing_page"
      end

      should "render an error message when the edition is not welsh" do
        get :cancel_scheduled_publishing_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#cancel_scheduled_publishing" do
    setup do
      @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
      @edition = FactoryBot.create(:edition, state: "scheduled_for_publishing", publish_at: Time.zone.now + 1.hour)
      login_as(@requester)
    end

    context "user has govuk_editor permission" do
      should "update the edition status to 'ready' and save the comment" do
        post :cancel_scheduled_publishing, params: {
          id: @edition.id,
          comment: "You shall not pass!",
        }

        assert_equal "Scheduling cancelled", flash[:success]
        @edition.reload
        assert_equal "ready", @edition.state
        assert_equal "You shall not pass!", @edition.latest_status_action.comment
        assert_equal @requester.id, @edition.latest_status_action.requester_id
      end

      should "not update the edition state and render 'cancel_scheduled_publishing' template with an error when an error occurs" do
        EditionProgressor.any_instance.expects(:progress).returns(false)

        post :cancel_scheduled_publishing, params: {
          id: @edition.id,
        }

        assert_template "secondary_nav_tabs/cancel_scheduled_publishing_page"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
        @edition.reload
        assert_equal "scheduled_for_publishing", @edition.state
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        post :cancel_scheduled_publishing, params: {
          id: @edition.id,
        }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "edition is not in a valid state to have scheduling cancelled" do
      setup do
        @requester = FactoryBot.create(:user, :govuk_editor, name: "Stub Requester")
        @edition = FactoryBot.create(:edition, state: "draft")
      end

      should "not update the edition state and render 'cancel_scheduled_publishing' template with an error" do
        post :cancel_scheduled_publishing, params: {
          id: @edition.id,
        }

        assert_equal "Edition is not in a state where scheduling can be cancelled", flash[:danger]

        assert_template "secondary_nav_tabs/cancel_scheduled_publishing_page"
        @edition.reload
        assert_equal "draft", @edition.state
      end
    end
  end

  context "#tagging" do
    setup do
      stub_linkables_with_data
    end

    should "render the 'Tagging' tab of the edit page" do
      get :tagging, params: { id: @edition.id }
      assert_template "show"
    end
  end

  context "#tagging_related_content_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      should "render the 'Tag related content' page" do
        get :tagging_related_content_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_related_content_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :tagging_related_content_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :tagging_related_content_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#tagging_reorder_related_content_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      should "render the 'Tag related content' page" do
        get :tagging_reorder_related_content_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_reorder_related_content_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :tagging_reorder_related_content_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have govuk_editor permission" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :tagging_reorder_related_content_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end

    context "reorder_related_content" do
      should "create tagging_update_form_values using reordered_related_items when it is present" do
        post :update_tagging, params: { "id" => @edition.id,
                                        "reordered_related_items" => { "/pay-vat" => "1", "/" => "3", "/universal-credit" => "2" },
                                        "tagging_tagging_update_form" => { "content_id" => "3db5234c-a87f-4a30-b058-adee1236329e",
                                                                           "previous_version" => "22",
                                                                           "tagging_type" => "reorder_related_content",
                                                                           "parent" => %w[1159936b-be05-44cb-b52c-87b3c9153959],
                                                                           "organisations" => %w[ebd15ade-73b2-4eaf-b1c3-43034a42eb37],
                                                                           "mainstream_browse_pages" => %w[1159936b-be05-44cb-b52c-87b3c9153959 932a86f4-4916-4d9f-99cb-dfd34d7ee5d1 a1c39054-4fd5-44e9-8d1d-0c7acd57a6a4] } }
        expected_reordered_related_items = %w[/pay-vat /universal-credit /]

        assert_equal expected_reordered_related_items, @controller.instance_variable_get(:@tagging_update_form_values).ordered_related_items
      end
    end
  end

  context "#tagging_organisation_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      should "render the 'Tag organisations' page" do
        get :tagging_organisations_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_organisations_page"
      end

      should "render the edit page and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :tagging_organisations_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end

      should "render the edit page and display an error message if invalid organisation data is submitted" do
        Tagging::TaggingUpdateForm.stubs(:publish!).raises(StandardError)

        post :update_tagging, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      setup do
        user = FactoryBot.create(:user)
        login_as(user)
      end

      should "render an error message" do
        get :tagging_organisations_page, params: { id: @edition.id }
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not a Welsh edition" do
        login_as_welsh_editor

        get :tagging_organisations_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#tagging_mainstream_browse_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      should "render the 'Tag to a browse page' page" do
        get :tagging_mainstream_browse_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_mainstream_browse_page"
      end

      should "render the tagging tab and display an error message if an error occurs during the request" do
        Tagging::TaggingUpdateForm.stubs(:build_from_publishing_api).raises(StandardError)

        get :tagging_mainstream_browse_page, params: { id: @edition.id }

        assert_template "show"
        assert_equal "Due to a service problem, the request could not be made", flash[:danger]
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :tagging_mainstream_browse_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user is a Welsh editor and non-Welsh edition" do
        login_as_welsh_editor

        get :tagging_mainstream_browse_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#tagging_remove_breadcrumb_page" do
    setup do
      stub_linkables_with_data
    end

    context "user has govuk_editor permission" do
      should "render the remove breadcrumb page" do
        get :tagging_remove_breadcrumb_page, params: { id: @edition.id }
        assert_template "secondary_nav_tabs/tagging_remove_breadcrumb_page"
      end
    end

    context "user does not have editor permissions" do
      should "render an error message if the user is not a govuk_editor" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :tagging_remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh" do
        login_as_welsh_editor

        get :tagging_remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user is not a govuk_editor and tries to remove breadcrumb" do
        user = FactoryBot.create(:user)
        login_as(user)

        get :tagging_remove_breadcrumb_page, params: { id: @edition.id }

        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "render an error message if the user has welsh_editor permission and the edition is not Welsh and tries to remove breadcrumb" do
        login_as_welsh_editor

        get :tagging_remove_breadcrumb_page, params: { id: @edition.id }

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
          Edition.any_instance.stubs(:destroy!).raises(ActiveRecord::RecordInvalid.new)

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

  context "#edit_reviewer" do
    context "user without required permissions" do
      context "Welsh editor and non-Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "show permission error and redirect to edition path" do
          get :edit_reviewer, params: { id: @edition.id }

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
          get :edit_reviewer, params: { id: @edition.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end
    end

    context "user with required permissions" do
      context "Welsh editor and Welsh edition" do
        setup do
          @welsh_in_review_edition = FactoryBot.create(:answer_edition, :in_review, :welsh)
          login_as_welsh_editor
        end

        should "be able to navigate successfully to edit reviewer path" do
          get :edit_reviewer, params: { id: @welsh_in_review_edition.id }

          assert_response :success
        end
      end

      should "be able to navigate to the edit reviewer path" do
        @in_review_edition = FactoryBot.create(:answer_edition, :in_review)
        get :edit_reviewer, params: { id: @in_review_edition.id }

        assert_response :success
      end

      %i[draft amends_needed fact_check fact_check_received ready scheduled_for_publishing published archived].each do |edition_state|
        context "edition in '#{edition_state}' state" do
          setup do
            @edition = FactoryBot.create(:edition, state: edition_state, publish_at: Time.zone.now + 1.hour)
          end

          should "redirect to edition path with error message" do
            get :edit_reviewer, params: { id: @edition.id }

            assert_redirected_to edition_path
            assert_equal "Cannot edit the reviewer of an edition that is not in review.", flash[:danger]
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

        assert_template "secondary_nav_tabs/edit_assignee_page"
        assert_equal "Due to a service problem, the assigned person couldn't be saved", flash[:danger]
      end

      should "show error when new assignee does not have editor permission" do
        new_assignee = FactoryBot.create(:user, name: "Stub User")
        patch :update_assignee, params: { id: @edition.id, assignee_id: new_assignee.id }

        assert_template "secondary_nav_tabs/edit_assignee_page"
        assert_equal "Chosen assignee does not have correct editor permissions.", flash[:danger]
      end

      should "show error when no assignee option is selected" do
        patch :update_assignee, params: { id: @edition.id }

        assert_template "secondary_nav_tabs/edit_assignee_page"
        assert_equal "Select a person to assign", flash[:danger]
      end

      should "show error when a non-existent assignee ID is provided" do
        patch :update_assignee, params: { id: @edition.id, assignee_id: "non-existent ID" }

        assert_template "secondary_nav_tabs/edit_assignee_page"
        assert_equal "Due to a service problem, the assigned person couldn't be saved", flash[:danger]
      end
    end
  end

  context "#update_reviewer" do
    context "user without required permissions" do
      context "Welsh editor and non-Welsh edition" do
        setup do
          login_as_welsh_editor
        end

        should "show permission error and redirect to edition path" do
          patch :update_reviewer, params: { id: @edition.id, reviewer_id: @user.id }

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
          patch :update_reviewer, params: { id: @edition.id, reviewer_id: @user.id }

          assert_redirected_to edition_path(@edition)
          assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        end
      end
    end

    context "user with required permissions" do
      setup do
        @in_review_edition = FactoryBot.create(:answer_edition, :in_review, reviewer: "2i Reviewer")
        @reviewer = FactoryBot.create(:user, :govuk_editor, name: "2i Reviewer")
        @user = FactoryBot.create(:user, :govuk_editor)
        login_as(@user)
      end

      should "be able to assign themselves as 2i reviewer" do
        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: @user.name }

        assert_redirected_to edition_path(@in_review_edition.id)
        assert_equal "You are now the 2i reviewer of this edition", flash[:success]
      end

      should "be able to assign another user as 2i reviewer" do
        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: @reviewer.name }

        assert_redirected_to edition_path(@in_review_edition.id)
        assert_equal "2i Reviewer is now the 2i reviewer of this edition", flash[:success]
      end

      should "update the 2i reviewer" do
        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: @reviewer.name }
        @in_review_edition.reload
        assert_equal @reviewer.name, @in_review_edition.reviewer
        assert_equal "2i Reviewer is now the 2i reviewer of this edition", flash[:success]
      end

      should "be able to unassign the current 2i reviewer" do
        @in_review_edition.reviewer = @reviewer

        assert_equal "2i Reviewer", @in_review_edition.reviewer

        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: "none" }

        @in_review_edition.reload

        assert_nil @in_review_edition.reviewer
        assert_equal "2i reviewer removed", flash[:success]
      end

      should "show an error when the save fails" do
        Edition.any_instance.stubs(:save).returns(false)
        new_reviewer = FactoryBot.create(:user, :govuk_editor, name: "Updated 2i reviewer")
        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: new_reviewer.id }

        assert_template "secondary_nav_tabs/edit_reviewer_page"
        assert_equal "The selected 2i reviewer could not be saved.", flash[:danger]
      end

      should "show an error when database save fails" do
        Edition.any_instance.stubs(:save).raises(StandardError)
        new_reviewer = FactoryBot.create(:user, :govuk_editor, name: "Updated 2i reviewer")
        patch :update_reviewer, params: { id: @in_review_edition.id, reviewer_id: new_reviewer.id }

        assert_template "secondary_nav_tabs/edit_reviewer_page"
        assert_equal "Due to a service problem, the reviewer couldn’t be saved.", flash[:danger]
      end

      should "show an error when user saves with a missing parameter" do
        patch :update_reviewer, params: { id: @in_review_edition.id }

        assert_template "secondary_nav_tabs/edit_reviewer_page"
        assert_equal "Select a person to assign", flash[:danger]
      end

      context "Welsh editor and Welsh edition" do
        setup do
          login_as_welsh_editor
          @welsh_in_review_edition = FactoryBot.create(:answer_edition, :in_review, :welsh)
        end

        should "be able to successfully update 2i reviewer" do
          patch :update_reviewer, params: { id: @welsh_in_review_edition.id, reviewer_id: @user.id }

          @welsh_in_review_edition.reload

          assert_equal @user.id.to_s, @welsh_in_review_edition.reviewer
        end
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

      assert_equal "External links title can't be blank", flash[:danger]
    end

    should "display an error message when the url is blank" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "foo", url: "", _destroy: false }],
        },
      }

      assert flash[:danger].include? "External links URL can't be blank"
    end

    should "display an error message when the url is invalid" do
      patch :update_related_external_links, params: {
        id: @edition.id,
        artefact: {
          external_links_attributes: [{ title: "foo", url: "an-invalid-url", _destroy: false }],
        },
      }

      assert_equal "External links URL is invalid", flash[:danger]
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
      edition_one = FactoryBot.create(:answer_edition, :published)
      edition_two = FactoryBot.create(:answer_edition, :published, panopticon_id: edition_one.panopticon_id)

      get :diff, params: { id: edition_two.id }

      assert_template "diff"
    end
  end

private

  def description(edition)
    edition.format.underscore.humanize.downcase
  end
end
