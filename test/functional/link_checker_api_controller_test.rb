require "test_helper"
require "gds_api/test_helpers/link_checker_api"

class LinkCheckerApiControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::LinkCheckerApi

  def generate_signature(body, key)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), key, body)
  end

  def create_edition_link_check_report
    FactoryBot.create(:edition, :with_link_check_report,
                                 batch_id: 5,
                                 link_uris: ['https://www.gov.uk']).link_check_reports.first
  end

  def create_answer_edition_with_link_check_report
    FactoryBot.create(:answer_edition_with_link_check_report, batch_id: 5,
                                                               link_uris: ['https://www.gov.uk']).link_check_reports.first
  end

  def create_campaign_edition_with_link_check_report
    FactoryBot.create(:campaign_edition_with_link_check_report, batch_id: 5,
                                                                 link_uris: ['https://www.gov.uk']).link_check_reports.first
  end

  def edition_link_check_report
    @edition_link_check_report ||= create_edition_link_check_report
  end

  def answer_edition_link_check_report
    @answer_edition_link_check_report ||= create_answer_edition_with_link_check_report
  end

  def campaign_edition_link_check_report
    @campaign_edition_with_link_check_report ||= create_campaign_edition_with_link_check_report
  end

  def set_headers(post_body)
    headers = {
      "Content-Type": "application/json",
      "X-LinkCheckerApi-Signature": generate_signature(post_body.to_json, Rails.application.secrets.link_checker_api_secret_token)
    }

    request.headers.merge! headers
  end

  context "when working on an edition" do
    setup do
      edition_link_check_report
    end

    should "update the LinkCheckerReport of edition on POST" do
      post_body = link_checker_api_batch_report_hash(
        id: 5,
        links: [
          { uri: @link, status: "ok" },
        ]
      )

      set_headers(post_body)

      post :callback, params: post_body

      edition_link_check_report.reload

      assert_response :success
      assert 'completed', edition_link_check_report.status
    end
  end

  context "Answer Edition a subclasses of edition" do
    setup do
      answer_edition_link_check_report
    end

    should "update LinkCheckerReport on POST" do
      post_body = link_checker_api_batch_report_hash(
        id: 5,
        links: [
          { uri: @link, status: "ok" },
        ]
      )

      set_headers(post_body)

      post :callback, params: post_body

      answer_edition_link_check_report.reload

      assert_response :success
      assert 'completed', answer_edition_link_check_report.status
    end
  end

  context "CampaignEdition a subclasses of edition" do
    setup do
      campaign_edition_link_check_report
    end

    should "update the LinkCheckerReport on POST" do
      post_body = link_checker_api_batch_report_hash(
        id: 5,
        links: [
          { uri: @link, status: "ok" },
        ]
      )

      set_headers(post_body)

      post :callback, params: post_body

      campaign_edition_link_check_report.reload

      assert_response :success
      assert 'completed', campaign_edition_link_check_report.status
    end
  end
end
