require "integration_test_helper"
class FactCheckResponseControllerTest < IntegrationTest
  setup do
    @test_strategy.switch!(:fact_check_manager_api, true)
    @edition = FactoryBot.create(:answer_edition, :fact_check)
  end

  def invalid_non_strings
    [123, %w[invalid], { invalid: true }, true]
  end

  context "#process_response" do
    should "return a success response with valid params" do
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true }, as: :json
      @edition.reload

      assert_response :success
      assert @edition.actions.last.requester_name == "Joe Bloggs"
      assert @edition.state == "fact_check_received"
    end

    should "use default comment when accepted with no comment provided" do
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true }, as: :json
      @edition.reload

      assert_response :success
      assert @edition.actions.last.comment == "Changes are correct."
    end

    should "use default comment when accepted with comment provided" do
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true, comment: "Custom comment" }, as: :json
      @edition.reload

      assert_response :success
      assert @edition.actions.last.comment == "Changes are correct."
    end

    should "use provided comment when rejected" do
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: false, comment: "Custom comment" }, as: :json
      @edition.reload

      assert_response :success
      assert @edition.actions.last.comment == "Custom comment"
    end

    should "return 422 when rejected with no comment provided" do
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: false }, as: :json

      assert_response :unprocessable_entity
      assert_includes response.parsed_body["errors"], "comment must be provided if the fact check is rejected"
    end

    %i[edition_id responder_name accepted].each do |param|
      should "return 422 when missing #{param}" do
        params = { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true }
        params.delete(param)
        post api_fact_check_response_path, params: params, as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["errors"], "#{param} is missing"
      end
    end

    %i[edition_id responder_name comment].each do |param|
      should "return 422 with invalid #{param} param" do
        invalid_non_strings.each do |invalid_value|
          params = { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: false, comment: "Custom message" }
          params[param] = invalid_value
          post api_fact_check_response_path, params: params, as: :json

          assert_response :unprocessable_entity
          assert_includes response.parsed_body["errors"], "#{param} must be a string"
        end
      end
    end

    should "return 422 when invalid accepted param is provided" do
      ["invalid", 123, %w[invalid], { accepted: true }].each do |param|
        params = { edition_id: @edition.id, responder_name: "Joe Bloggs" }
        params[:accepted] = param
        post api_fact_check_response_path, params: params, as: :json

        assert_response :unprocessable_entity
        assert_includes response.parsed_body["errors"], "accepted must be boolean"
      end
    end

    should "return 404 with non-existent edition_id" do
      post api_fact_check_response_path, params: { edition_id: "invalid", responder_name: "Joe Bloggs", accepted: true }, as: :json

      assert_response :not_found
    end

    should "return 422 with edition in invalid non-published state" do
      @edition = FactoryBot.create(:answer_edition, :draft)

      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true }, as: :json

      assert_response :unprocessable_entity
      assert_includes response.parsed_body["errors"], "State Edition is not in a state where fact check can be submitted"
    end

    should "return 422 with published edition" do
      @edition = FactoryBot.create(:answer_edition, :published)
      post api_fact_check_response_path, params: { edition_id: @edition.id, responder_name: "Joe Bloggs", accepted: true }, as: :json

      assert_response :unprocessable_entity
      assert_includes response.parsed_body["errors"], "State Edition is not in a state where fact check can be submitted"
    end
  end
end
