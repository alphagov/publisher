require 'test_helper'

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @guide = FactoryGirl.create(:guide_edition)
    @user = User.create
    @controller.stubs(:current_user).returns(@user)
  end

  test "should be able to create a folder path for a given publication" do
    l = LocalTransactionEdition.new
    assert_equal "app/views/admin/local_transactions", @controller.admin_template_folder_for(l)
    g = GuideEdition.new
    assert_equal "app/views/admin/guides", @controller.admin_template_folder_for(g)
  end

  test "an appropriate error message is shown if new edition failed" do
    @user.stubs(:new_version).with(@guide).returns(false)
    post :create, :id => @guide.id
    assert_response 302
    assert_equal "Failed to create new edition: couldn't initialise", flash[:alert]
  end

  test "should update status via progress and redirect to parent" do
    post :progress,
      :id       => @guide.id,
      :activity => {
        "request_type"       => "send_fact_check",
        "comment"            => "Blah",
        "email_addresses"    => "user@example.com",
        "customised_message" => "Hello"
      }

    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id

    @guide.reload
    assert @guide.status_is?(Action::SEND_FACT_CHECK)
  end

  test "should assign after creation" do
    bob = User.create

    @guide.state = 'ready'
    User.create(:name => 'test').publish @guide, comment: "Publishing this"

    post :create, :id => @guide.id,
      :edition  => { :assigned_to_id => bob.id }

    @new_guide = WholeEdition.where(panopticon_id: @guide.panopticon_id).last
    assert_equal bob, @new_guide.assigned_to
  end

  test "should not assign after creation if assignment is blank" do
    @bob = User.create
    @bob.publish @guide, comment: "Publishing this"

    post :create,
      :id => @guide.id,
      :edition  => { :assigned_to_id => "" }

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
    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id

    @guide.reload
    assert !@guide.lined_up?
    assert @guide.draft?
  end
end
