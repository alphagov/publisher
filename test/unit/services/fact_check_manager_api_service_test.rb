require "test_helper"

class FactCheckManagerApiServiceTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
    @edition = FactoryBot.create(:answer_edition)
    stub_post_new_fact_check_request
  end

  context ".request_fact_check" do
    should "call the fact check manager api adapter" do
      Services.fact_check_manager_api.expects(:post_fact_check).returns("stub response")

      FactCheckManagerApiService.request_fact_check(@edition, @user, "test@email.com")
    end
  end

  context ".build_post_payload" do
    should "build a properly formatted payload" do
      payload = FactCheckManagerApiService.build_post_payload(@edition, @user, "stub@email.com")
      assert payload.values_at(0..5, 7..) == [@edition.id,
                                              "New Title",
                                              "Ben",
                                              "joe1@bloggs.com",
                                              "some body",
                                              "",
                                              "stub@email.com"]
      assert payload[6].is_a?(ActiveSupport::TimeWithZone)
    end
  end
end
