require 'test_helper'

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    without_metadata_denormalisation(Guide) do
      @guide = Guide.create(:name => "test", :slug=>"test")
    end
    @user = User.create
    @controller.stubs(:current_user).returns(@user)
  end

  test "an appropriate error message is shown if new edition failed" do
    @user.stubs(:new_version).with(@guide.editions.first).returns(false)
    post :create, :guide_id => @guide.id
    assert_response 302
    assert_equal "Failed to create new edition: couldn't initialise", flash[:alert]
  end
  
  test "should update status via progress and redirect to parent" do
    without_metadata_denormalisation(Guide) do
      post :progress,
        :guide_id => @guide.id,
        :id       => @guide.editions.last.id,
        :activity => {
          "request_type"       => "request_fact_check",
          "comment"            => "Blah",
          "email_addresses"    => "user@example.com",
          "customised_message" => "Hello"
        }
    end
  
    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id
  
    @guide.reload
    assert @guide.editions.last.status_is?(Action::FACT_CHECK_REQUESTED)
  end
  
  test "should assign after creation" do
    bob = User.create
    @guide.editions.each do |e|
       @guide.publish e, "Publishing this"
    end
  
    without_metadata_denormalisation(Guide) do
      post :create,
        :guide_id => @guide.id,
        :edition  => { :assigned_to_id => bob.id }
    end
  
    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end
  
  test "should not assign after creation if assignment is blank" do
    bob = User.create
    @guide.editions.each do |e|
       @guide.publish e, "Publishing this"
    end
  
    without_metadata_denormalisation(Guide) do
      post :create,
        :guide_id => @guide.id,
        :edition  => { :assigned_to_id => "" }
    end
  
    @guide.reload
    assert_nil @guide.editions.last.assigned_to
  end
  
  test "should update assignment" do
    bob = User.create
  
    without_metadata_denormalisation(Guide) do
      post :update,
        :guide_id => @guide.id,
        :id       => @guide.editions.last.id,
        :edition  => { :assigned_to_id => bob.id }
    end
  
    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end
  
  test "should not create a new action if the assignment is unchanged" do
    bob = User.create
    @user.assign(@guide.editions.last, bob)
  
    without_metadata_denormalisation(Guide) do
      post :update,
        :guide_id => @guide.id,
        :id       => @guide.editions.last.id,
        :edition  => { :assigned_to_id => bob.id }
    end
  
    @guide.reload
    assert_equal 1, @guide.editions.last.actions.select{ |a| a.request_type == Action::ASSIGNED }.length
  end
  
  test "should not update assignment if the assignment is blank" do
    bob = User.create
    @user.assign(@guide.editions.last, bob)
  
    without_metadata_denormalisation(Guide) do
      post :update,
        :guide_id => @guide.id,
        :id       => @guide.editions.last.id,
        :edition  => { :assigned_to_id => "" }
    end
  
    @guide.reload
    assert_equal bob, @guide.editions.last.assigned_to
  end
  
  test "should show the edit page again if updating fails" do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/test.js").
      with(:headers => {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{}", :headers => {})
    
    without_metadata_denormalisation(Guide) do
      Guide.expects(:find).returns(@guide)
      @guide.editions.last.stubs(:update_attributes).returns(false)
      @guide.editions.last.expects(:errors).at_least_once.returns({:title => ['values']})

      post :update,
        :guide_id => @guide.id,
        :id       => @guide.editions.last.id,
        :edition  => { :assigned_to_id => "" }
      assert_response 200
    end
  end
  
  test "should not progress to fact check if the email addresses were blank" do
    without_metadata_denormalisation(Guide) do
      post :progress, {
        :guide_id => @guide.id.to_s,
        :id       => @guide.editions.last.id.to_s,
        :activity => { 'request_type' => "request_fact_check" }
      }
      assert_equal "Couldn't request fact check for guide", flash[:alert]
    end
  end

  test "should show the edit page after starting work" do
    without_metadata_denormalisation(Guide) do
      post :start_work, {
        :guide_id => @guide.id.to_s,
        :id       => @guide.editions.last.id.to_s
      }
    end
    assert_redirected_to :controller => "admin/guides", :action => "show", :id => @guide.id
  
    @guide.reload
    assert ! @guide.lined_up
    assert @guide.latest_edition.status_is?(Action::WORK_STARTED)
  end
end
