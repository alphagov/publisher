require 'test_helper'

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user

    @guide = FactoryGirl.create(:guide_edition)
    @transaction = TransactionEdition.create!(title: "test", slug: "test", panopticon_id: '123')
    @programme = ProgrammeEdition.create(title: "test", slug: "test", panopticon_id: 12345)

    stub_request(:delete, "#{Plek.current.find("arbiter")}/slugs/test").to_return(:status => 200)
    panopticon_has_metadata("id" => "test", "name" => "FOOOO")
    panopticon_has_metadata("id" => "12345", "name" => "Test", "slug" => "test")
  end

  test "it renders the new template successfully if creation fails" do
    LocalTransactionsSource.stubs(:find_current_lgsl).returns(nil)
    post :create, "edition" => {"kind" => "local_transaction", "lgsl_code"=>"801", "panopticon_id"=>"827"}
    assert_equal '200', response.code
  end

  test "should be able to create a view path for a given publication" do
    l = LocalTransactionEdition.new
    assert_equal "app/views/admin/local_transactions", @controller.admin_template_folder_for(l)
    g = GuideEdition.new
    assert_equal "app/views/admin/guides", @controller.admin_template_folder_for(g)
  end

  test "an appropriate error message is shown if new edition failed" do
    @user.stubs(:new_version).with(@guide).returns(false)
    post :duplicate, :id => @guide.id
    assert_response 302
    assert_equal "Failed to create new edition: couldn't initialise", flash[:alert]
  end

  test "should update status via progress and redirect to parent" do
    @guide.update_attribute(:state, :ready)

    post :progress,
      :id       => @guide.id,
      :activity => {
        "request_type"       => "send_fact_check",
        "comment"            => "Blah",
        "email_addresses"    => "user@example.com",
        "customised_message" => "Hello"
      }

    assert_redirected_to :controller => "admin/editions", :action => "show", :id => @guide.id
    assert_equal "Guide updated", flash[:notice]

    reloaded = WholeEdition.find(@guide.id)
    assert reloaded.fact_check?
  end

  test "should assign after creating new edition" do
    bob = User.create

    @guide.state = 'ready'
    User.create(:name => 'test').publish(@guide, comment: "Publishing this")

    post :duplicate, :id => @guide.id,
      :edition  => { :assigned_to_id => bob.id, :kind => 'guide' }

    @new_guide = WholeEdition.where(panopticon_id: @guide.panopticon_id).last
    assert_equal bob, @new_guide.assigned_to
  end

  test "should not assign after creating a new edition if assignment is blank" do
    @bob = User.create
    @bob.publish(@guide, comment: "Publishing this")

    post :duplicate,
      :id => @guide.id,
      :edition  => { :assigned_to_id => "", :kind => 'guide' }

    @guide.reload
    assert_nil @guide.assigned_to
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

    WholeEdition.expects(:find).returns(@guide)
    @guide.stubs(:update_attributes).returns(false)
    @guide.expects(:errors).at_least_once.returns({:title => ['values']})

    post :update,
      :id       => @guide.id,
      :edition  => { :assigned_to_id => "" }
    assert_response 200
  end

  test "should not progress to fact check if the email addresses were blank" do
    post :progress, {
      :id       => @guide.id.to_s,
      :activity => { 'request_type' => "send_fact_check" }
    }
    assert_equal "Couldn't send fact check for guide", flash[:alert]
  end

  test "should show the edit page after starting work" do
    post :start_work, {
      :id => @guide.id.to_s
    }
    assert_redirected_to :controller => "admin/editions", :action => "show", :id => @guide.id

    @guide.reload
    assert !@guide.lined_up?
    assert @guide.draft?
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
    assert_not_nil assigns(:resource)
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
    @programme.publish
    @programme.save!
    assert @programme.published?
    assert !@programme.can_destroy?

    assert_difference('ProgrammeEdition.count', 0) do
      delete :destroy, :id => @programme.id
    end
  end
end
