module FactCheckManagerApiHelpers
  def stub_post_new_fact_check_request(success: true)
    response = if success
                 GdsApi::Response.new(code: 200)
               else
                 GdsApi::HTTPErrorResponse.new(code: 422)
               end
    Services.fact_check_manager_api.stubs(:post_fact_check).returns(response)
  end
end
