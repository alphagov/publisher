require 'test_helper'

class EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    stub_linkables
  end

  context "#create" do
    setup do
      @artefact = FactoryGirl.create(:artefact,
          slug: "test",
          kind: "answer",
          name: "test",
          owning_app: "publisher")
    end

    should "report publication counts on creation" do
      Publisher::Application.edition_state_count_reporter.expects(:report)
      post :create, "edition" => {
        "kind" => "answer",
        "panopticon_id" => @artefact.id,
        "title" => "a title"
      }
    end

    should "update publishing API upon creation of new edition" do
      UpdateWorker.expects(:perform_async)

      post :create, "edition" => {
        "kind" => "answer",
        "panopticon_id" => @artefact.id,
        "title" => "a title"
      }
    end

    should "render the lgsl edit form successfully if creation fails" do
      lgsl_code = 800
      FactoryGirl.create(:local_service, lgsl_code: lgsl_code)
      artefact = FactoryGirl.create(:artefact)

      post :create, "edition" => {
        "kind" => "local_transaction",
        "lgsl_code" => lgsl_code,
        "panopticon_id" => artefact.id,
        "title" => "a title",
      }
      assert_equal '302', response.code

      post :create, "edition" => {
        "kind" => "local_transaction",
        "lgsl_code" => lgsl_code + 1,
        "panopticon_id" => artefact.id,
        "title" => "a title"
      }
      assert_equal '200', response.code
    end
  end

  context "#template_folder_for" do
    should "be able to create a view path for a given publication" do
      l = LocalTransactionEdition.new
      assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
      g = GuideEdition.new
      assert_equal "app/views/guides", @controller.template_folder_for(g)
    end
  end

  context "#duplicate" do
    setup do
      @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
      EditionDuplicator.any_instance.expects(:duplicate).returns(true)
      EditionDuplicator.any_instance.expects(:new_edition).returns(@guide)
    end

    should "delegate complexity of duplication to appropriate collaborator" do
      post :duplicate, id: @guide.id
      assert_response 302
      assert_equal "New edition created", flash[:success]
    end

    should "update the publishing API upon duplication of an edition" do
      UpdateWorker.expects(:perform_async).with(@guide.id.to_s)
      post :duplicate, id: @guide.id
    end
  end

  context "#progress" do
    setup do
      @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    end

    should "update status via progress and redirect to parent" do
      EditionProgressor.any_instance.expects(:progress).returns(true)
      EditionProgressor.any_instance.expects(:status_message).returns("Guide updated")

      post :progress,
        id: @guide.id,
        edition: {
          activity: {
            "request_type"       => "send_fact_check",
            "comment"            => "Blah",
            "email_addresses"    => "user@example.com",
            "customised_message" => "Hello"
          }
        }

      assert_redirected_to controller: "editions", action: "show", id: @guide.id
      assert_equal "Guide updated", flash[:success]
    end

    should "set an error message if it couldn't progress an edition" do
      EditionProgressor.any_instance.expects(:progress).returns(false)
      EditionProgressor.any_instance.expects(:status_message).returns("I failed")

      post :progress, id: @guide.id.to_s,
        edition: {
          activity: {
            'request_type' => "send_fact_check",
            "email_addresses" => ""
          }
        }
      assert_equal "I failed", flash[:danger]
    end

    should "squash multiparameter attributes into a time field that has time-zone information" do
      EditionProgressor.any_instance.expects(:progress).with(has_entry('publish_at', Time.zone.local(2014, 3, 4, 14, 47)))

      publish_at_params = {
        "publish_at(1i)" => "2014",
        "publish_at(2i)" => "3",
        "publish_at(3i)" => "4",
        "publish_at(4i)" => "14",
        "publish_at(5i)" => "47"
      }

      post :progress, id: @guide.id.to_s,
        edition: {
          activity: {
            "request_type" => 'schedule_for_publishing'
          }.merge(publish_at_params)
        }
    end
  end

  context "#update" do
    setup do
      @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    end

    should "update assignment" do
      bob = FactoryGirl.create(:user)

      post :update,
        id: @guide.id,
        edition: { assigned_to_id: bob.id }

      @guide.reload
      assert_equal bob, @guide.assigned_to
    end

    should "not create a new action if the assignment is unchanged" do
      bob = FactoryGirl.create(:user)
      @user.assign(@guide, bob)

      post :update,
        id: @guide.id,
        edition: { assigned_to_id: bob.id }

      @guide.reload
      assert_equal 1, @guide.actions.count { |a| a.request_type == Action::ASSIGN }
    end

    should "show the edit page again if updating fails" do
      Edition.expects(:find).returns(@guide)
      @guide.stubs(:update_attributes).returns(false)
      @guide.expects(:errors).at_least_once.returns(title: ['values'])

      post :update,
        id: @guide.id,
        edition: { assigned_to_id: "" }
      assert_response 200
    end

    should "show the resource base errors if present" do
      Edition.expects(:find).returns(@guide)
      @guide.stubs(:update_attributes).returns(false)
      @guide.expects(:errors).at_least_once.returns(base: ["Editions scheduled for publishing can't be edited"])

      post :update, id: @guide.id, edition: {}

      assert_equal "Editions scheduled for publishing can't be edited", flash[:danger]
    end

    should "save the edition changes while performing an activity" do
      post :update, id: @guide.id, commit: "Send to 2nd pair of eyes",
        edition: {
          title: "Updated title",
          activity_request_review_attributes: {
            request_type: "request_review",
            comment: "Please review the updated title"
          }
        }

      @guide.reload
      assert_equal "Updated title", @guide.title
      assert_equal "in_review", @guide.state
      assert_equal "Please review the updated title", @guide.actions.last.comment
    end

    should "update the publishing API on successful update" do
      UpdateWorker.expects(:perform_async).with(@guide.id.to_s)

      post :update, id: @guide.id, edition: { title: "Updated title" }
    end
  end

  context "#review" do
    setup do
      artefact = FactoryGirl.create(:artefact)

      @guide = FactoryGirl.create(
        :guide_edition,
        state: "in_review",
        review_requested_at: Time.zone.now,
        panopticon_id: artefact.id
      )
    end

    should "update the reviewer" do
      bob = FactoryGirl.create(:user, name: "bob")

      put :review,
        id: @guide.id,
        edition: { reviewer: bob.name }

      @guide.reload
      assert_equal bob.name, @guide.reviewer
    end
  end

  context "with Business Support areas" do
    setup do
      artefact = FactoryGirl.create(:artefact)

      @business_support_edition = FactoryGirl.create(
        :business_support_edition,
        panopticon_id: artefact.id,
      )

      update_params = {
        # select2 produces an array beginning with an empty string
        "area_gss_codes" => [
          "",
          "N07000001",
          "E15000003",
        ],
      }

      post :update,
        :id => @business_support_edition.id,
        :edition => update_params

      @business_support_edition.reload
    end

    should "update area GSS codes" do
      assert_equal ["N07000001", "E15000003"],
        @business_support_edition.area_gss_codes
    end
  end

  context "#destroy" do
    setup do
      artefact1 = FactoryGirl.create(:artefact, slug: "test",
          kind: "transaction",
          name: "test",
          owning_app: "publisher")
      @transaction = TransactionEdition.create!(title: "test", slug: "test", panopticon_id: artefact1.id)

      artefact2 = FactoryGirl.create(:artefact, slug: "test2",
          kind: "guide",
          name: "test",
          owning_app: "publisher")
      @guide = GuideEdition.create(title: "test", slug: "test2", panopticon_id: artefact2.id)

      stub_request(:delete, "#{Plek.current.find('arbiter')}/slugs/test").to_return(status: 200)
    end

    should "destroy transaction" do
      assert @transaction.can_destroy?
      assert_difference('TransactionEdition.count', -1) do
        delete :destroy, id: @transaction.id
      end
      assert_redirected_to(:controller => "root", "action" => "index")
    end

    should "can't destroy published transaction" do
      @transaction.state = 'ready'
      stub_register_published_content
      @transaction.publish
      assert !@transaction.can_destroy?
      @transaction.save!
      assert_difference('TransactionEdition.count', 0) do
        delete :destroy, id: @transaction.id
      end
    end

    should "destroy guide" do
      assert @guide.can_destroy?
      assert_difference('GuideEdition.count', -1) do
        delete :destroy, id: @guide.id
      end
      assert_redirected_to(:controller => "root", "action" => "index")
    end

    should "can't destroy published guide" do
      @guide.state = 'ready'
      @guide.save!
      stub_register_published_content
      @guide.publish
      @guide.save!
      assert @guide.published?
      assert !@guide.can_destroy?

      assert_difference('GuideEdition.count', 0) do
        delete :destroy, id: @guide.id
      end
    end
  end

  context "#index" do
    should "editions index redirects to root" do
      get :index
      assert_response :redirect
      assert_redirected_to(:controller => "root", "action" => "index")
    end
  end

  context "#show" do
    setup do
      artefact2 = FactoryGirl.create(:artefact, slug: "test2",
          kind: "guide",
          name: "test",
          owning_app: "publisher")
      @guide = GuideEdition.create(title: "test", slug: "test2", panopticon_id: artefact2.id)
    end

    should "requesting a publication that doesn't exist returns a 404" do
      get :show, id: '4e663834e2ba80480a0000e6'
      assert_response 404
    end

    should "we can view a guide" do
      get :show, id: @guide.id
      assert_response :success
      refute_nil assigns(:resource)
    end
  end

  context "#diff" do
    should "we can diff the last edition" do
      first_edition = FactoryGirl.create(:guide_edition, state: "published")
      second_edition = first_edition.build_clone(GuideEdition)
      second_edition.save
      second_edition.reload

      get :diff, id: second_edition.id
      assert_response :success
    end
  end

  context "given a simple smart answer" do
    setup do
      @artefact = FactoryGirl.create(:artefact, :slug => "foo", :name => "Foo", :kind => "simple_smart_answer", :owning_app => "publisher")
      @edition = FactoryGirl.create(:simple_smart_answer_edition, :body => "blah", :state => "draft", :slug => "foo", :panopticon_id => @artefact.id)
      @edition.nodes.build(:kind => "question", :slug => "question-1", :title => "Question One", :options_attributes => [
        { :label => "Option One", :next_node => "outcome-1" },
        { :label => "Option Two", :next_node => "outcome-2" }
      ])
      @edition.nodes.build(:kind => "outcome", :slug => "outcome-1", :title => "Outcome One")
      @edition.nodes.build(:kind => "outcome", :slug => "outcome-2", :title => "Outcome Two")
      @edition.save!
    end

    should "remove an option and node from simple smart answer in single request" do
      atts = {
        :nodes_attributes => {
          "0" => {
            "id" => @edition.nodes.all[0].id,
            "options_attributes" => {
              "0" => { "id" => @edition.nodes.first.options.all[0].id },
              "1" => { "id" => @edition.nodes.first.options.all[1].id, "_destroy" => "1" }
            },
          },
          "1" => {
            "id" => @edition.nodes.all[1].id
          },
          "2" => {
            "id" => @edition.nodes.all[2].id,
            "_destroy" => "1"
          }
        }
      }
      put :update, :id => @edition.id, :edition => atts
      assert_redirected_to edition_path(@edition)

      @edition.reload

      assert_equal 2, @edition.nodes.count
      assert_equal 1, @edition.nodes.where(:kind => "question").count
      assert_equal 1, @edition.nodes.where(:kind => "outcome").count

      question = @edition.nodes.where(:kind => "question").first
      assert_equal 1, question.options.count
      assert_equal "Option One", question.options.first.label
    end
  end
end
