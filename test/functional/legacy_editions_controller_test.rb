require "test_helper"

class LegacyEditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api

    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:restrict_access_by_org, true)
  end

  context "#create" do
    setup do
      @artefact = FactoryBot.create(
        :artefact,
        slug: "test",
        kind: "answer",
        name: "test",
        owning_app: "publisher",
      )
    end

    should "report publication counts on creation" do
      Publisher::Application.edition_state_count_reporter.expects(:report)
      post :create,
           params: {
             "edition" => {
               "kind" => "answer",
               "panopticon_id" => @artefact.id,
               "title" => "a title",
             },
           }
    end

    should "update publishing API upon creation of new edition" do
      UpdateWorker.expects(:perform_async)

      post :create,
           params: {
             "edition" => {
               "kind" => "answer",
               "panopticon_id" => @artefact.id,
               "title" => "a title",
             },
           }
    end

    should "render the lgsl and lgil edit form successfully if creation fails" do
      lgsl_code = 800
      FactoryBot.create(
        :local_service,
        lgsl_code:,
      )
      artefact = FactoryBot.create(:artefact)

      post :create,
           params: {
             "edition" => {
               "kind" => "local_transaction",
               "lgsl_code" => lgsl_code,
               "lgil_code" => 1,
               "panopticon_id" => artefact.id,
               "title" => "a title",
             },
           }
      assert_equal "302", response.code

      post :create,
           params: {
             "edition" => {
               "kind" => "local_transaction",
               "lgsl_code" => lgsl_code + 1,
               "lgil_code" => 1,
               "panopticon_id" => artefact.id,
               "title" => "a title",
             },
           }
      assert_equal "200", response.code
    end
  end

  context "#template_folder_for" do
    should "be able to create a view path for a given publication" do
      l = FactoryBot.build(:local_transaction_edition)
      assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
      g = FactoryBot.build(:guide_edition)
      assert_equal "app/views/guides", @controller.template_folder_for(g)
    end
  end

  context "#duplicate" do
    context "Standard behaviour" do
      setup do
        @guide = FactoryBot.create(:guide_edition)
        EditionDuplicator.any_instance.expects(:duplicate).returns(true)
        EditionDuplicator.any_instance.expects(:new_edition).returns(@guide)
      end

      should "delegate complexity of duplication to appropriate collaborator" do
        post :duplicate, params: { id: @guide.id }
        assert_response :found
        assert_equal "New edition created", flash[:success]
      end

      should "update the publishing API upon duplication of an edition" do
        UpdateWorker.expects(:perform_async).with(@guide.id.to_s)
        post :duplicate, params: { id: @guide.id }
      end
    end

    context "Welsh editors" do
      setup { login_as_welsh_editor }

      should "be able to duplicate Welsh editions" do
        edition = FactoryBot.create(:guide_edition, :published, :welsh)
        artefact = edition.artefact

        post :duplicate, params: { id: edition.id }

        assert_response :found
        assert_redirected_to edition_path(artefact.latest_edition)
        assert_not_equal edition, artefact.latest_edition
        assert_equal "New edition created", flash[:success]
      end

      should "not be able to duplicate non-Welsh editions" do
        edition = FactoryBot.create(:guide_edition, :published)
        artefact = edition.artefact

        post :duplicate, params: { id: edition.id }

        assert_response :found
        assert_redirected_to edition_path(edition)
        assert_equal edition, artefact.latest_edition
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#progress" do
    setup do
      @guide = FactoryBot.create(:guide_edition)
    end

    should "update status via progress and redirect to parent" do
      EditionProgressor.any_instance.expects(:progress).returns(true)
      EditionProgressor.any_instance.expects(:status_message).returns("Guide updated")

      post :progress,
           params: {
             id: @guide.id,
             edition: {
               activity: {
                 "request_type" => "send_fact_check",
                 "comment" => "Blah",
                 "email_addresses" => "user@example.com",
                 "customised_message" => "Hello",
               },
             },
           }

      assert_redirected_to controller: "editions", action: "show", id: @guide.id
      assert_equal "Guide updated", flash[:success]
    end

    should "set an error message if it couldn't progress an edition" do
      EditionProgressor.any_instance.expects(:progress).returns(false)
      EditionProgressor.any_instance.expects(:status_message).returns("I failed")

      post :progress,
           params: {
             id: @guide.id.to_s,
             edition: {
               activity: {
                 "request_type" => "send_fact_check",
                 "email_addresses" => "",
               },
             },
           }
      assert_equal "I failed", flash[:danger]
    end

    should "squash multiparameter attributes into a time field that has time-zone information" do
      EditionProgressor.any_instance.expects(:progress).with(has_entry("publish_at", Time.zone.local(2014, 3, 4, 14, 47)))

      publish_at_params = {
        "publish_at(1i)" => "2014",
        "publish_at(2i)" => "3",
        "publish_at(3i)" => "4",
        "publish_at(4i)" => "14",
        "publish_at(5i)" => "47",
      }

      post :progress,
           params: {
             id: @guide.id.to_s,
             edition: {
               activity: {
                 "request_type" => "schedule_for_publishing",
               }.merge(publish_at_params),
             },
           }
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @artefact = FactoryBot.create(:artefact)
        @edition = FactoryBot.create(:guide_edition, :scheduled_for_publishing, panopticon_id: @artefact.id)
        @welsh_edition = FactoryBot.create(:guide_edition, :scheduled_for_publishing, :welsh)
      end

      should "be able to cancel scheduled publishing for Welsh editions" do
        ScheduledPublisher.expects(:cancel_scheduled_publishing).with(@welsh_edition.id.to_s).once

        post(
          :progress,
          params: {
            id: @welsh_edition.id,
            commit: "Cancel scheduled publishing",
            edition: {
              activity: {
                request_type: "cancel_scheduled_publishing",
                comment: "cancel this!",
              },
            },
          },
        )

        assert_redirected_to edition_path(@welsh_edition)
        assert_equal flash[:success], "Guide updated"
        @welsh_edition.reload
        assert_equal @welsh_edition.state, "ready"
      end

      should "not be able to cancel scheduled publishing for non-Welsh editions" do
        ScheduledPublisher.expects(:cancel_scheduled_publishing).with(@edition.id.to_s).never

        post(
          :progress,
          params: {
            id: @edition.id,
            commit: "Cancel scheduled publishing",
            edition: {
              activity: {
                request_type: "cancel_scheduled_publishing",
                comment: "cancel this!",
              },
            },
          },
        )

        assert_redirected_to edition_path(@edition)
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
        @edition.reload
        assert_equal @edition.state, "scheduled_for_publishing"
      end

      should "be able to skip fact checks for Welsh editions" do
        @welsh_edition.update!(state: "fact_check")

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
        @edition.update!(state: "fact_check")

        post :progress,
             params: {
               id: @edition.id,
               edition: {
                 activity: {
                   request_type: "skip_fact_check",
                   comment: "Fact check skipped by request.",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "fact_check"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end
    end
  end

  context "#update" do
    setup do
      @guide = FactoryBot.create(:guide_edition)
    end

    should "update assignment" do
      bob = FactoryBot.create(:user, :govuk_editor)

      post :update,
           params: {
             id: @guide.id,
             edition: { assigned_to_id: bob.id },
           }

      @guide.reload
      assert_equal bob, @guide.assigned_to
    end

    should "clear assignment if no assignment is passed" do
      post :update,
           params: {
             id: @guide.id,
             edition: {},
           }

      @guide.reload
      assert_nil @guide.assigned_to
    end

    should "not create a new action if the assignment is unchanged" do
      bob = FactoryBot.create(:user, :govuk_editor)
      @user.assign(@guide, bob)

      post :update,
           params: {
             id: @guide.id,
             edition: { assigned_to_id: bob.id },
           }

      @guide.reload
      assert_equal(1, @guide.actions.count { |a| a.request_type == Action::ASSIGN })
    end

    should "show the edit page again if updating fails" do
      Edition.expects(:find).returns(@guide)
      @guide.stubs(:update).returns(false)
      @guide.errors.add(:title, "values")

      post :update,
           params: {
             id: @guide.id,
             edition: { assigned_to_id: "" },
           }
      assert_response :ok
    end

    should "save the edition changes while performing an activity" do
      post :update,
           params: {
             id: @guide.id,
             commit: "Send to 2nd pair of eyes",
             edition: {
               title: "Updated title",
               activity_request_review_attributes: {
                 request_type: "request_review",
                 comment: "Please review the updated title",
               },
             },
           }

      @guide.reload
      assert_equal "Updated title", @guide.title
      assert_equal "in_review", @guide.state
      assert_equal "Please review the updated title", @guide.actions.last.comment
    end

    should "update the publishing API on successful update" do
      UpdateWorker.expects(:perform_async).with(@guide.id.to_s, false)

      post :update,
           params: {
             id: @guide.id,
             edition: {
               title: "Updated title",
             },
           }
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @edition = FactoryBot.create(:guide_edition, :ready)
        @welsh_edition = FactoryBot.create(:guide_edition, :ready, :welsh)
      end

      should "be able to update Welsh editions" do
        post :update,
             params: {
               id: @welsh_edition.id,
               edition: {
                 title: "Updated title",
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal @welsh_edition.title, "Updated title"
      end

      should "not be able to update non-Welsh editions" do
        post :update,
             params: {
               id: @edition.id,
               edition: {
                 title: "Updated title",
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_not_equal @edition.title, "Updated title"
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "be able to assign users to Welsh editions" do
        assignees = [FactoryBot.create(:user, :welsh_editor), FactoryBot.create(:user, :govuk_editor)]
        assignees.each do |assignee|
          post :update,
               params: {
                 id: @welsh_edition.id,
                 edition: {
                   assigned_to_id: assignee.id,
                 },
               }

          assert_redirected_to edition_path(@welsh_edition)
          @welsh_edition.reload
          assert_equal @welsh_edition.assigned_to, assignee
        end
      end

      should "not be able to assign users to non-Welsh editions" do
        assignees = [FactoryBot.create(:user, :welsh_editor), FactoryBot.create(:user, :govuk_editor)]
        assignees.each do |assignee|
          post :update,
               params: {
                 id: @edition.id,
                 edition: {
                   assigned_to_id: assignee.id,
                 },
               }

          assert_redirected_to edition_path(@edition)
          assert_equal flash[:danger], "You do not have correct editor permissions for this action."
          @edition.reload
          assert_nil @edition.assigned_to
        end
      end

      should "not be able to be assigned to non-Welsh editions" do
        login_as_govuk_editor
        assignee = FactoryBot.create(:user, :welsh_editor)

        post :update,
             params: {
               id: @edition.id,
               edition: {
                 assigned_to_id: assignee.id,
               },
             }

        assert_redirected_to edition_path(@edition)
        assert_equal flash[:danger], "Chosen assignee does not have correct editor permissions."
        @edition.reload
        assert_nil @edition.assigned_to
      end

      should "be able to schedule publishing for Welsh editions" do
        ScheduledPublisher.expects(:enqueue).with(@welsh_edition)

        post(
          :update,
          params: {
            id: @welsh_edition.id,
            edition: {
              activity_schedule_for_publishing_attributes: {
                request_type: "schedule_for_publishing",
                "publish_at(1i)" => "2100",
                "publish_at(2i)" => "12",
                "publish_at(3i)" => "21",
                "publish_at(4i)" => "10",
                "publish_at(5i)" => "35",
              },
            },
            commit: "Schedule for publishing",
          },
        )

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal @welsh_edition.state, "scheduled_for_publishing"
        assert_equal flash[:notice], "Guide edition was successfully updated."
      end

      should "not be able to schedule publishing for non-Welsh editions" do
        ScheduledPublisher.expects(:enqueue).with(@edition).never

        post(
          :update,
          params: {
            id: @edition.id,
            edition: {
              activity_schedule_for_publishing_attributes: {
                request_type: "schedule_for_publishing",
                "publish_at(1i)" => "2020",
                "publish_at(2i)" => "12",
                "publish_at(3i)" => "21",
                "publish_at(4i)" => "10",
                "publish_at(5i)" => "35",
              },
            },
            commit: "Schedule for publishing",
          },
        )

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "ready"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to publish a Welsh edition" do
        UpdateWorker.expects(:perform_async).with(@welsh_edition.id.to_s, true)

        post :update,
             params: {
               id: @welsh_edition.id,
               commit: "Send to publish",
               edition: {
                 activity_publish_attributes: {
                   request_type: "publish",
                   comment: "Publish this!",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal @welsh_edition.state, "published"
        assert_equal flash[:success], "Guide updated"
      end

      should "not be able to publish a non-Welsh edition" do
        UpdateWorker.expects(:perform_async).with(@edition.id.to_s, true).never

        post :update,
             params: {
               id: @edition.id,
               commit: "Send to publish",
               edition: {
                 activity_publish_attributes: {
                   request_type: "publish",
                   comment: "Publish this!",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "ready"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to approve a review for Welsh editions" do
        welsh_edition = FactoryBot.create(:guide_edition, :in_review, :welsh)

        UpdateWorker.expects(:perform_async).with(welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: welsh_edition.id,
               commit: "No changes needed",
               edition: {
                 activity_approve_review_attributes: {
                   request_type: :approve_review,
                   comment: "LGTM",
                 },
               },
             }

        assert_redirected_to edition_path(welsh_edition)
        welsh_edition.reload
        assert_equal welsh_edition.state, "ready"
        assert_equal flash[:success], "Guide updated"
      end

      should "not be able to approve a review for non-Welsh editions" do
        edition = FactoryBot.create(:guide_edition, :in_review)

        UpdateWorker.expects(:perform_async).with(edition.id.to_s, false).never

        post :update,
             params: {
               id: edition.id,
               commit: "No changes needed",
               edition: {
                 activity_approve_review_attributes: {
                   request_type: :approve_review,
                   comment: "LGTM",
                 },
               },
             }

        assert_redirected_to edition_path(edition)
        edition.reload
        assert_equal edition.state, "in_review"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to request a review for Welsh editions" do
        welsh_edition = FactoryBot.create(:guide_edition, :draft, :welsh)

        UpdateWorker.expects(:perform_async).with(welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: welsh_edition.id,
               commit: "Send to 2nd pair of eyes",
               edition: {
                 activity_request_review_attributes: {
                   request_type: :request_review,
                   comment: "Please review",
                 },
               },
             }

        assert_redirected_to edition_path(welsh_edition)
        welsh_edition.reload
        assert_equal welsh_edition.state, "in_review"
        assert_equal flash[:success], "Guide updated"
      end

      should "not be able to request a review for non-Welsh editions" do
        edition = FactoryBot.create(:guide_edition, :draft)

        UpdateWorker.expects(:perform_async).with(edition.id.to_s, false).never

        post :update,
             params: {
               id: edition.id,
               commit: "Send to 2nd pair of eyes",
               edition: {
                 activity_request_review_attributes: {
                   request_type: :request_review,
                   comment: "Please review",
                 },
               },
             }

        assert_redirected_to edition_path(edition)
        edition.reload
        assert_equal edition.state, "draft"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to request amendments to a review for Welsh editions" do
        UpdateWorker.expects(:perform_async).with(@welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: @welsh_edition.id,
               commit: "Request amendments",
               edition: {
                 activity_request_amendments_attributes: {
                   request_type: :request_amendments,
                   comment: "Suggestion here",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal @welsh_edition.state, "amends_needed"
        assert_equal flash[:success], "Guide updated"
      end

      should "not be able to request amendments to a review for non-Welsh editions" do
        UpdateWorker.expects(:perform_async).with(@edition.id.to_s, false).never

        post :update,
             params: {
               id: @edition.id,
               commit: "Request amendments",
               edition: {
                 activity_request_amendments_attributes: {
                   request_type: :request_amendments,
                   comment: "Suggestion here",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "ready"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to request a fact check for Welsh editions" do
        UpdateWorker.expects(:perform_async).with(@welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: @welsh_edition.id,
               commit: "Send to Fact check",
               edition: {
                 activity_send_fact_check_attributes: {
                   request_type: "send_fact_check",
                   comment: "Blah",
                   email_addresses: "user@example.com",
                   customised_message: "Hello",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal flash[:success], "Guide updated"
        assert_equal @welsh_edition.state, "fact_check"
      end

      should "not be able to request a fact check for non-Welsh editions" do
        UpdateWorker.expects(:perform_async).with(@edition.id.to_s, false).never

        post :update,
             params: {
               id: @edition.id,
               commit: "Send to Fact check",
               edition: {
                 activity_send_fact_check_attributes: {
                   request_type: "send_fact_check",
                   comment: "Blah",
                   email_addresses: "user@example.com",
                   customised_message: "Hello",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "ready"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to resend fact check emails for Welsh editions" do
        @welsh_edition.update!(state: "fact_check")

        previous_action = Action.new(
          request_type: "send_fact_check",
          email_addresses: "user@example.com",
          comment: "Blah",
          customised_message: "Hello",
          edition: @welsh_edition,
        )
        Edition.any_instance.stubs(:latest_status_action).returns(previous_action)

        UpdateWorker.expects(:perform_async).with(@welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: @welsh_edition.id,
               commit: "Resend fact check email",
               edition: {
                 activity_resend_fact_check_attributes: {
                   request_type: "resend_fact_check",
                   comment: "Blah",
                   email_addresses: "user@example.com",
                   customised_message: "Hello",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal flash[:success], "Guide updated"
        assert_equal @welsh_edition.state, "fact_check"
      end

      should "not be able to resend fact check emails for non-Welsh editions" do
        @edition.update!(state: "fact_check")
        UpdateWorker.expects(:perform_async).with(@edition.id.to_s, false).never

        post :update,
             params: {
               id: @edition.id,
               commit: "Resend fact check email",
               edition: {
                 activity_resend_fact_check_attributes: {
                   request_type: "resend_fact_check",
                   comment: "Blah",
                   email_addresses: "user@example.com",
                   customised_message: "Hello",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "fact_check"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to approve a fact check for Welsh editions" do
        UpdateWorker.expects(:perform_async).with(@welsh_edition.id.to_s, false)

        post :update,
             params: {
               id: @welsh_edition.id,
               commit: "Approve Fact check",
               edition: {
                 activity_approve_fact_check_attributes: {
                   request_type: "approve_fact_check",
                   comment: "lgtm",
                 },
               },
             }

        assert_redirected_to edition_path(@welsh_edition)
        @welsh_edition.reload
        assert_equal "Guide edition was successfully updated.", flash[:notice]
        assert_equal @welsh_edition.state, "ready"
      end

      should "not be able to approve a fact check for non-Welsh editions" do
        @edition.update!(state: "fact_check_received")
        UpdateWorker.expects(:perform_async).with(@edition.id.to_s, false).never

        post :update,
             params: {
               id: @edition.id,
               commit: "Approve Fact check",
               edition: {
                 activity_approve_fact_check_attributes: {
                   request_type: "approve_fact_check",
                   comment: "lgtm",
                 },
               },
             }

        assert_redirected_to edition_path(@edition)
        @edition.reload
        assert_equal @edition.state, "fact_check_received"
        assert_equal flash[:danger], "You do not have correct editor permissions for this action."
      end
    end
  end

  context "#review" do
    setup do
      artefact = FactoryBot.create(:artefact)

      @guide = FactoryBot.create(
        :guide_edition,
        state: "in_review",
        review_requested_at: Time.zone.now,
        panopticon_id: artefact.id,
      )
    end

    should "update the reviewer" do
      bob = FactoryBot.create(:user, name: "bob")

      put :review,
          params: {
            id: @guide.id,
            edition: { reviewer: bob.name },
          }

      @guide.reload
      assert_equal bob.name, @guide.reviewer
    end

    should "not be able to update the reviewer when edition is scheduled for publishing" do
      bob = FactoryBot.create(:user, name: "bob")
      edition = FactoryBot.create(:edition, :scheduled_for_publishing)

      put :review,
          params: {
            id: edition.id,
            edition: { reviewer: bob.name },
          }

      assert_response(:found)
      assert_equal "Something went wrong when attempting to claim 2i.", flash[:danger]
    end

    context "Welsh editors" do
      setup do
        @welsh_guide = FactoryBot.create(:guide_edition, :welsh, :in_review)
        login_as_welsh_editor
        @welsh_user = @user
      end

      should "be able to claim a review for Welsh editions" do
        put :review,
            params: {
              id: @welsh_guide.id,
              edition: { reviewer: @welsh_user.name },
            }

        assert_redirected_to edition_path(@welsh_guide)
        assert_equal "You are the reviewer of this guide.", flash[:success]
        @welsh_guide.reload
        assert_equal @welsh_user.name, @welsh_guide.reviewer
      end

      should "not be able to claim a review for non-Welsh editions" do
        put :review,
            params: {
              id: @guide.id,
              edition: { reviewer: @welsh_user.name },
            }

        assert_redirected_to edition_path(@guide)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
        @guide.reload
        assert_nil @guide.reviewer
      end
    end
  end

  context "#destroy" do
    setup do
      artefact1 = FactoryBot.create(
        :artefact,
        slug: "test",
        kind: "transaction",
        name: "test",
        owning_app: "publisher",
      )
      @transaction = FactoryBot.create(:transaction_edition, title: "test", slug: "test", panopticon_id: artefact1.id)

      artefact2 = FactoryBot.create(
        :artefact,
        slug: "test2",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      @guide = FactoryBot.create(:guide_edition, title: "test", slug: "test2", panopticon_id: artefact2.id)

      stub_request(:delete, "#{Plek.find('arbiter')}/slugs/test").to_return(status: 200)
    end

    should "destroy transaction" do
      assert @transaction.can_destroy?
      assert_difference("TransactionEdition.count", -1) do
        delete :destroy, params: { id: @transaction.id }
      end
      assert_redirected_to root_path
    end

    should "can't destroy published transaction" do
      @transaction.state = "ready"
      stub_register_published_content
      @transaction.publish
      assert_not @transaction.can_destroy?
      @transaction.save!
      assert_difference("TransactionEdition.count", 0) do
        delete :destroy, params: { id: @transaction.id }
      end
    end

    should "destroy guide" do
      assert @guide.can_destroy?
      assert_difference("GuideEdition.count", -1) do
        delete :destroy, params: { id: @guide.id }
      end
      assert_redirected_to root_path
    end

    should "can't destroy published guide" do
      @guide.state = "ready"
      @guide.save!
      stub_register_published_content
      @guide.publish
      @guide.save!
      assert @guide.published?
      assert_not @guide.can_destroy?

      assert_difference("GuideEdition.count", 0) do
        delete :destroy, params: { id: @guide.id }
      end
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @welsh_guide = FactoryBot.create(:guide_edition, :welsh)
      end

      should "not be able to destroy non-Welsh editions" do
        assert_difference("GuideEdition.count", 0) do
          delete :destroy, params: { id: @guide.id }
        end

        assert_redirected_to edition_path(@guide)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end

      should "be able to destroy Welsh editions" do
        assert_difference("GuideEdition.count", -1) do
          delete :destroy, params: { id: @welsh_guide.id }
        end

        assert_redirected_to root_path
        assert_equal "Edition deleted", flash[:success]
      end
    end
  end

  context "#index" do
    should "editions index redirects to root" do
      get :index
      assert_response :redirect
      assert_redirected_to root_path
    end
  end

  context "#show" do
    setup do
      artefact2 = FactoryBot.create(
        :artefact,
        slug: "test2",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      @guide = FactoryBot.create(:guide_edition, title: "test", slug: "test2", panopticon_id: artefact2.id)
    end

    should "requesting a publication that doesn't exist returns a 404" do
      get :show, params: { id: "101" }
      assert_response :not_found
    end

    should "we can view a guide" do
      get :show, params: { id: @guide.id }
      assert_response :success
      assert_not_nil assigns(:resource)
    end

    should "render a link to the diagram when edition is a simple smart answer" do
      simple_smart_answer_artefact = FactoryBot.create(
        :artefact,
        slug: "my-simple-smart-answer",
        kind: "guide",
        name: "test",
        owning_app: "publisher",
      )
      simple_smart_answer = FactoryBot.create(:simple_smart_answer_edition,
                                              title: "test ssa",
                                              panopticon_id: simple_smart_answer_artefact.id)

      get :show, params: { id: simple_smart_answer.id }

      assert_select ".link-check-report p", { text: "View the flow diagram (opens in a new tab)" } do
        assert_select "a[href=?]", diagram_edition_path(simple_smart_answer).to_s,
                      { count: 1, text: "flow diagram (opens in a new tab)" }
      end
    end

    should "not render a link to the diagram when edition is not a simple smart answer" do
      get :show, params: { id: @guide.id }
      assert_select "p", { count: 0, text: "View the flow diagram (opens in a new tab)" }
    end
  end

  context "#admin" do
    setup do
      @guide = FactoryBot.create(:guide_edition)
    end

    should "show the admin page for the edition" do
      get :admin, params: { id: @guide.id }

      assert_response :success
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @welsh_guide = FactoryBot.create(:guide_edition, :welsh)
      end

      should "be able to see the admin page for Welsh editions" do
        get :admin, params: { id: @welsh_guide.id }

        assert_response :success
      end

      should "not be able to see the admin page for non-Welsh editions" do
        get :admin, params: { id: @guide.id }

        assert_redirected_to edition_path(@guide)
        assert_equal "You do not have correct editor permissions for this action.", flash[:danger]
      end
    end
  end

  context "#diff" do
    should "we can diff the last edition" do
      first_edition = FactoryBot.create(:guide_edition, state: "published")
      second_edition = first_edition.build_clone(GuideEdition)
      second_edition.save!
      second_edition.reload

      get :diff, params: { id: second_edition.id }
      assert_response :success
    end
  end

  context "#unpublish" do
    setup do
      @guide = FactoryBot.create(:guide_edition, :published)
      @redirect_url = "https://www.example.com/somewhere_else"
    end

    should "update publishing API upon unpublishing" do
      UnpublishService.expects(:call).with(@guide.artefact, @user, @redirect_url)

      post :process_unpublish,
           params: {
             id: @guide.id,
             redirect_url: @redirect_url,
           }
    end

    should "redirect and display success message after successful unpublish" do
      UnpublishService.stubs(:call).with(@guide.artefact, @user, @redirect_url).returns(true)

      post :process_unpublish,
           params: {
             id: @guide.id,
             redirect_url: @redirect_url,
           }

      assert_redirected_to root_path
      assert_equal "Content unpublished and redirected", flash[:notice]
    end

    should "not be able to unpublish with invalid redirect url" do
      post :process_unpublish,
           params: {
             id: @guide.id,
             redirect_url: "invalid redirect url",
           }

      assert_equal "Redirect path is invalid. Guide has not been unpublished.", flash[:danger]
    end

    should "alert if unable to unpublish" do
      UnpublishService.stubs(:call).with(@guide.artefact, @user, @redirect_url).returns(nil)

      post :process_unpublish,
           params: {
             id: @guide.id,
             redirect_url: @redirect_url,
           }

      assert_equal "Due to a service problem, the edition couldn't be unpublished", flash[:alert]
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
        @welsh_guide = FactoryBot.create(:guide_edition, :published, :welsh)
      end

      should "not be able to access the unpublish page of non-Welsh editions" do
        get :unpublish, params: { id: @guide.id }

        assert_redirected_to edition_path(@guide)
        assert_equal "You do not have permission to see this page.", flash[:danger]
      end

      should "not be able to access the unpublish page of Welsh editions" do
        get :unpublish, params: { id: @welsh_guide.id }

        assert_redirected_to edition_path(@welsh_guide)
        assert_equal "You do not have permission to see this page.", flash[:danger]
      end

      should "not be allowed to unpublish a Welsh edition" do
        UnpublishService.expects(:call).with(@welsh_guide.artefact, @user, @redirect_url).never

        post :process_unpublish,
             params: {
               id: @welsh_guide.id,
               redirect_url: @redirect_url,
             }

        assert_redirected_to edition_path(@welsh_guide)
        @welsh_guide.reload
        assert_equal @welsh_guide.state, "published"
        assert_equal "You do not have permission to see this page.", flash[:danger]
      end

      should "not be allowed to unpublish a non-Welsh edition" do
        UnpublishService.expects(:call).with(@guide.artefact, @user, @redirect_url).never

        post :process_unpublish,
             params: {
               id: @guide.id,
               redirect_url: @redirect_url,
             }

        assert_redirected_to edition_path(@guide)
        @guide.reload
        assert_equal @guide.state, "published"
        assert_equal "You do not have permission to see this page.", flash[:danger]
      end
    end
  end

  context "given a simple smart answer" do
    setup do
      @artefact = FactoryBot.create(:artefact, slug: "foo", name: "Foo", kind: "simple_smart_answer", owning_app: "publisher")
      @edition = FactoryBot.create(:simple_smart_answer_edition, body: "blah", state: "draft", slug: "foo", panopticon_id: @artefact.id)
      @edition.nodes.build(
        kind: "question",
        slug: "question-1",
        title: "Question One",
        options_attributes: [
          { label: "Option One", next_node: "outcome-1" },
          { label: "Option Two", next_node: "outcome-2" },
        ],
      )
      @edition.nodes.build(kind: "outcome", slug: "outcome-1", title: "Outcome One")
      @edition.nodes.build(kind: "outcome", slug: "outcome-2", title: "Outcome Two")
      @edition.save!
    end

    should "remove an option and node from simple smart answer in single request" do
      atts = {
        nodes_attributes: {
          "0" => {
            "id" => @edition.nodes.all[0].id,
            "options_attributes" => {
              "0" => { "id" => @edition.nodes.first.options.all[0].id },
              "1" => { "id" => @edition.nodes.first.options.all[1].id, "_destroy" => "1" },
            },
          },
          "1" => {
            "id" => @edition.nodes.all[1].id,
          },
          "2" => {
            "id" => @edition.nodes.all[2].id,
            "_destroy" => "1",
          },
        },
      }
      put :update,
          params: {
            id: @edition.id,
            edition: atts,
          }
      assert_redirected_to edition_path(@edition)

      @edition.reload

      assert_equal 2, @edition.nodes.count
      assert_equal 1, @edition.nodes.where(kind: "question").count
      assert_equal 1, @edition.nodes.where(kind: "outcome").count

      question = @edition.nodes.where(kind: "question").first
      assert_equal 1, question.options.count
      assert_equal "Option One", question.options.first.label
    end
  end

  context "#diagram" do
    context "given a simple smart answer exists" do
      setup do
        @artefact = FactoryBot.create(:artefact, slug: "foo", name: "Foo", kind: "simple_smart_answer", owning_app: "publisher")
        @edition = FactoryBot.create(:simple_smart_answer_edition, body: "blah", state: "draft", slug: "foo", panopticon_id: @artefact.id)
        @edition.save!
      end

      should "render a diagram page for it" do
        get :diagram, params: { id: @edition.id }

        assert_response :success
        assert_select "title", "Diagram for #{@edition.title} | GOV.UK Publisher"
      end
    end

    context "given a non-simple smart answer exists" do
      setup do
        @welsh_guide = FactoryBot.create(:guide_edition, :welsh, :in_review)
      end

      should "return a 404" do
        get :diagram, params: { id: @welsh_guide.id }
        assert_response :not_found
      end
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

    %i[metadata history].each do |action|
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
    %i[show metadata history admin unpublish].each do |action|
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
end
