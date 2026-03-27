module FactCheckManagerApiHelpers
  def stub_post_new_fact_check_request(success: true)
    response = if success
                 GdsApi::Response.new(code: 200)
               else
                 GdsApi::HTTPErrorResponse.new(code: 422)
               end
    Services.fact_check_manager_api.stubs(:post_fact_check).returns(response)
  end

  def stub_post_resend_fact_check_emails(success: true)
    if success
      Services.fact_check_manager_api.stubs(:post_resend_emails).returns(GdsApi::Response.new(code: 200))
    else
      Services.fact_check_manager_api.stubs(:post_resend_emails).raises(GdsApi::HTTPErrorResponse.new(code: 422), "Example error message")
    end
  end

  def stub_patch_update_fact_check_content(success: true, source_id: "12345")
    if success
      mock_http_response = stub(
        code: 200,
        body: {
          "source_app" => "publisher",
          "source_id" => source_id,
        }.to_json,
      )

      Services.fact_check_manager_api.stubs(:patch_update_content).returns(GdsApi::Response.new(mock_http_response))
    else
      Services.fact_check_manager_api.stubs(:patch_update_content).raises(GdsApi::HTTPErrorResponse.new(code: 422), "Example error message")
    end
  end
end
