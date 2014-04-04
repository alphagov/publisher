require 'test_helper'

class EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    artefact1 = FactoryGirl.create(:artefact, slug: "test",
        kind: "transaction",
        name: "test",
        owning_app: "publisher")
    @transaction = TransactionEdition.create!(title: "test", slug: "test", panopticon_id: artefact1.id)

    artefact2 = FactoryGirl.create(:artefact, slug: "test2",
        kind: "programme",
        name: "test",
        owning_app: "publisher")
    @programme = ProgrammeEdition.create(title: "test", slug: "test2", panopticon_id: artefact2.id)

    stub_request(:delete, "#{Plek.current.find("arbiter")}/slugs/test").to_return(:status => 200)
  end

  test "it renders the lgsl edit form successfully if creation fails" do
    lgsl_code = 800
    local_service = FactoryGirl.create(:local_service, :lgsl_code=>lgsl_code)
    artefact = FactoryGirl.create(:artefact)

    post :create, "edition" => {"kind" => "local_transaction", "lgsl_code"=>lgsl_code, "panopticon_id"=>artefact.id, "title"=>"a title"}
    assert_equal '302', response.code

    post :create, "edition" => {"kind" => "local_transaction", "lgsl_code"=>lgsl_code+1, "panopticon_id"=>artefact.id, "title"=>"a title"}
    assert_equal '200', response.code
  end

  test "should be able to create a view path for a given publication" do
    l = LocalTransactionEdition.new
    assert_equal "app/views/local_transactions", @controller.template_folder_for(l)
    g = GuideEdition.new
    assert_equal "app/views/guides", @controller.template_folder_for(g)
  end

  test "delegates complexity of duplication to appropriate collaborator" do
    EditionDuplicator.any_instance.expects(:duplicate).returns(true)
    EditionDuplicator.any_instance.expects(:new_edition).returns(@guide)

    post :duplicate, :id => @guide.id
    assert_response 302
    assert_equal "New edition created", flash[:notice]
  end

  test "should update status via progress and redirect to parent" do
    EditionProgressor.any_instance.expects(:progress).returns(true)
    EditionProgressor.any_instance.expects(:status_message).returns("Guide updated")

    post :progress,
      :id       => @guide.id,
      :activity => {
        "request_type"       => "send_fact_check",
        "comment"            => "Blah",
        "email_addresses"    => "user@example.com",
        "customised_message" => "Hello"
      }

    assert_redirected_to :controller => "editions", :action => "show", :id => @guide.id
    assert_equal "Guide updated", flash[:notice]
  end

  test "should update assignment" do
    bob = User.create

    post :update,
      :id       => @guide.id,
      :edition  => { :assigned_to_id => bob.id }

    @guide.reload
    assert_equal bob, @guide.assigned_to
  end

  test "should not create a new action if the assignment is unchanged" do
    bob = User.create
    @user.assign(@guide, bob)

    post :update,
      :id       => @guide.id,
      :edition  => { :assigned_to_id => bob.id }

    @guide.reload
    assert_equal 1, @guide.actions.select { |a| a.request_type == Action::ASSIGN }.length
  end

  test "should not update assignment if the assignment is blank" do
    bob = User.create
    @user.assign(@guide, bob)

    post :update,
      :id       => @guide.id,
      :edition  => { :assigned_to_id => "" }

    @guide.reload
    assert_equal bob, @guide.assigned_to
  end

  test "should show the edit page again if updating fails" do
    panopticon_has_metadata(
      "id" => "test"
    )

    Edition.expects(:find).returns(@guide)
    @guide.stubs(:update_attributes).returns(false)
    @guide.expects(:errors).at_least_once.returns({:title => ['values']})

    post :update,
      :id       => @guide.id,
      :edition  => { :assigned_to_id => "" }
    assert_response 200
  end

  test "should show the resource base errors if present" do
    panopticon_has_metadata("id" => "test")
    Edition.expects(:find).returns(@guide)
    @guide.stubs(:update_attributes).returns(false)
    @guide.expects(:errors).at_least_once.returns({:base => ["Editions scheduled for publishing can't be edited"]})

    post :update, :id => @guide.id

    assert_equal "Editions scheduled for publishing can't be edited", flash[:alert]
  end

  test "should set an error message if it couldn't progress an edition" do
    EditionProgressor.any_instance.expects(:progress).returns(false)
    EditionProgressor.any_instance.expects(:status_message).returns("I failed")

    post :progress, {
      :id       => @guide.id.to_s,
      :activity => { 
        'request_type' => "send_fact_check",
        "email_addresses" => ""
      }
    }
    assert_equal "I failed", flash[:alert]
  end

  test "should squash multiparameter attributes" do
    EditionProgressor.any_instance.expects(:progress).with(has_key('publish_at'))

    publish_at_params = { "publish_at(1i)"=>"2014", "publish_at(2i)"=>"3", "publish_at(3i)"=>"4", 
                          "publish_at(4i)"=>"14", "publish_at(5i)"=>"47" }
    post :progress, { id: @guide.id.to_s, activity: { "request_type" => 'start_work' }.merge(publish_at_params) }
  end

  test "destroy transaction" do
    assert @transaction.can_destroy?
    assert_difference('TransactionEdition.count', -1) do
      delete :destroy, :id => @transaction.id
    end
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "can't destroy published transaction" do
    @transaction.state = 'ready'
    stub_register_published_content
    @transaction.publish
    assert !@transaction.can_destroy?
    @transaction.save!
    assert_difference('TransactionEdition.count', 0) do
      delete :destroy, :id => @transaction.id
    end
  end

  test "editions index redirects to root" do
    get :index
    assert_response :redirect
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "requesting a publication that doesn't exist returns a 404" do
    get :show, :id => '4e663834e2ba80480a0000e6'
    assert_response 404
  end

  test "we can view a programme" do
    get :show, :id => @programme.id
    assert_response :success
    refute_nil assigns(:resource)
  end

  test "destroy programme" do
    assert @programme.can_destroy?
    assert_difference('ProgrammeEdition.count', -1) do
      delete :destroy, :id => @programme.id
    end
    assert_redirected_to(:controller => "root", "action" => "index")
  end

  test "can't destroy published programme" do
    @programme.state = 'ready'
    @programme.save!
    stub_register_published_content
    @programme.publish
    @programme.save!
    assert @programme.published?
    assert !@programme.can_destroy?

    assert_difference('ProgrammeEdition.count', 0) do
      delete :destroy, :id => @programme.id
    end
  end

  test "we can diff the last edition" do
    first_edition = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id, state: "published")
    second_edition = first_edition.build_clone(GuideEdition)
    second_edition.save
    second_edition.reload

    get :diff, :id => second_edition.id
    assert_response :success
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
