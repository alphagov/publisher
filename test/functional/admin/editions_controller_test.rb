require 'test_helper'

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    @guide = Guide.create(:name => "test", :slug=>"test")
    @user = User.create
    @controller.stubs(:current_user).returns(@user)
  end

  test "should be able to create a folder path for a given publication" do
    l = LocalTransaction.new
    assert_equal "app/views/admin/local_transactions", @controller.admin_template_folder_for(l)

    g = Guide.new
    assert_equal "app/views/admin/guides", @controller.admin_template_folder_for(g)
  end

  test "an appropriate error message is shown if new edition failed" do
    @user.stubs(:new_version).with(@guide.editions.first).returns(false)
    post :create, :guide_id => @guide.id
    assert_response 302
    assert_equal "Failed to create new edition: couldn't initialise", flash[:alert]
  end

  test "should update status via progress and redirect to parent" do
    post :progress,
      :guide_id => @guide.id,
      :id       => @guide.editions.last.id,
      :activity => {
        "request_type"       => "send_fact_check",
        "comment"            => "Blah",
        "email_addresses"    => "user@example.com",
        "customised_message" => "Hello"
      }

    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id

    @guide.reload
    assert @guide.editions.last.status_is?(Action::SEND_FACT_CHECK)
  end

  test "should assign after creation" do
    bob = User.create

    @guide.editions.each do |e|
      e.state = 'ready'
      User.create(:name => 'test').publish e, comment: "Publishing this"
    end

    post :create,
      :guide_id => @guide.id,
      :edition  => { :assigned_to_id => bob.id }

    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end

  test "should not assign after creation if assignment is blank" do
    @bob = User.create
    @guide.editions.each do |e|
       @bob.publish e, comment: "Publishing this"
    end

    post :create,
      :guide_id => @guide.id,
      :edition  => { :assigned_to_id => "" }

    @guide.reload
    assert_nil @guide.editions.last.assigned_to
  end

  test "should update assignment" do
    bob = User.create

    post :update,
      :guide_id => @guide.id,
      :id       => @guide.editions.last.id,
      :edition  => { :assigned_to_id => bob.id }

    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end

  test "should not create a new action if the assignment is unchanged" do
    bob = User.create
    @user.assign(@guide.editions.last, bob)

    post :update,
      :guide_id => @guide.id,
      :id       => @guide.editions.last.id,
      :edition  => { :assigned_to_id => bob.id }

    @guide.reload
    assert_equal 1, @guide.editions.last.actions.select{ |a| a.request_type == Action::ASSIGN }.length
  end

  test "should not update assignment if the assignment is blank" do
    bob = User.create
    @user.assign(@guide.editions.last, bob)

    post :update,
      :guide_id => @guide.id,
      :id       => @guide.editions.last.id,
      :edition  => { :assigned_to_id => "" }

    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end

  test "should show the edit page again if updating fails" do
    panopticon_has_metadata(
      "id" => "test"
    )

    Guide.expects(:find).returns(@guide)
    @guide.editions.last.stubs(:update_attributes).returns(false)
    @guide.editions.last.expects(:errors).at_least_once.returns({:title => ['values']})

    post :update,
      :guide_id => @guide.id,
      :id       => @guide.editions.last.id,
      :edition  => { :assigned_to_id => "" }
    assert_response 200
  end

  test "should not progress to fact check if the email addresses were blank" do
    post :progress, {
      :guide_id => @guide.id.to_s,
      :id       => @guide.editions.last.id.to_s,
      :activity => { 'request_type' => "send_fact_check" }
    }
    assert_equal "Couldn't send fact check for guide", flash[:alert]
  end

  test "should show the edit page after starting work" do
    post :start_work, {
      :guide_id => @guide.id.to_s,
      :id       => @guide.editions.last.id.to_s
    }
    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id

    @guide.reload
    assert !@guide.has_lined_up?
    assert @guide.latest_edition.draft?
  end
end
