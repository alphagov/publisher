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
end
