module FactCheckManagerApiHelpers
  def notify_team_only_error
    GdsApi::HTTPErrorResponse.new(
      502,
      "Example error message",
      { "errors" => { "notify_error" => "One or more recipients not in GOV.UK Notify team. This error will not occur in Production.", "error_code" => 400 } },
    )
  end

  def stub_post_new_fact_check_request(success: true, source_id: "12345", notify_team_only: false)
    if success
      mock_http_response = stub(
        code: 200,
        body: {
          "source_app" => "publisher",
          "source_id" => source_id,
        }.to_json,
      )

      Services.fact_check_manager_api.stubs(:post_fact_check).returns(GdsApi::Response.new(mock_http_response))
    elsif notify_team_only
      Services.fact_check_manager_api.stubs(:post_fact_check).raises(notify_team_only_error)
    else
      Services.fact_check_manager_api.stubs(:post_fact_check).raises(GdsApi::HTTPErrorResponse.new(code: 422), "Example error message")
    end
  end

  def stub_post_resend_fact_check_emails(success: true, source_id: "12345", notify_team_only: false)
    if success
      mock_http_response = stub(
        code: 200,
        body: {
          "source_app" => "publisher",
          "source_id" => source_id,
        }.to_json,
      )

      Services.fact_check_manager_api.stubs(:post_resend_emails).returns(GdsApi::Response.new(mock_http_response))
    elsif notify_team_only
      Services.fact_check_manager_api.stubs(:post_resend_emails).raises(notify_team_only_error)
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
