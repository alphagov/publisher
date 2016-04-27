require 'integration_test_helper'

class RequestTracingTest < ActionDispatch::IntegrationTest
  setup do
    WebMock.reset!
    setup_users

    stub_request(:any, /publishing-api/)
    stub_request(:put, /panopticon/)
  end

  test "govuk_request_id is passed downstream across the worker boundary on publish" do
    Sidekiq::Testing.fake! do
      inbound_headers = { "HTTP_GOVUK_REQUEST_ID" => "12345-67890" }
      artefact = FactoryGirl.create(:artefact)

      # Create an edition.
      post "/editions", {
        edition: {
          panopticon_id: artefact.id,
          kind: "answer",
          title: "a title"
        }
      }, inbound_headers
      assert_equal 302, response.status
      edition = Edition.last

      # Transition the edition to 'in_review'
      post "/editions/#{edition.id}/progress", {
        edition: {
          activity: {
            request_type: :request_review
          }
        }
      }, inbound_headers
      assert_equal 302, response.status

      login_as(@reviewer)

      # Transition the edition to 'ready'
      post "/editions/#{edition.id}/progress", {
        edition: {
          activity: {
            request_type: :approve_review
          }
        }
      }, inbound_headers
      assert_equal 302, response.status

      # Transition the edition to 'published'
      post "/editions/#{edition.id}/progress", {
        edition: {
          activity: {
            request_type: :publish
          }
        }
      }, inbound_headers
      assert_equal 302, response.status

      worker_classes = Sidekiq::Worker.jobs.map(&:first).uniq
      worker_classes.each do |worker_class|
        while worker_class.jobs.any?
          GdsApi::GovukHeaders.clear_headers
          worker_class.perform_one
          GdsApi::GovukHeaders.clear_headers
        end
      end

      onward_headers = { "GOVUK-Request-Id" => "12345-67890" }
      content_id = artefact.content_id

      assert_requested(:put, %r|publishing-api.*content/#{content_id}|, times: 7, headers: onward_headers)
      assert_requested(:patch, %r|publishing-api.*links/#{content_id}|, headers: onward_headers)
      assert_requested(:post, %r|publishing-api.*content/#{content_id}/publish|, headers: onward_headers)
      assert_requested(:put, /panopticon/, headers: onward_headers)
    end
  end
end
