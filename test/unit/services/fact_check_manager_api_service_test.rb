require "test_helper"

class FactCheckManagerApiServiceTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user, :govuk_editor, uid: "123", name: "Ben")
    @edition = FactoryBot.create(:answer_edition)
    stub_holidays_used_by_fact_check
    stub_post_new_fact_check_request
  end

  context ".request_fact_check" do
    should "call the fact check manager api adapter" do
      Services.fact_check_manager_api.expects(:post_fact_check).returns("stub response")

      FactCheckManagerApiService.request_fact_check(@edition, @user, "test@email.com")
    end
  end

  context ".build_post_payload" do
    should "build a properly formatted payload with one email address" do
      travel_to Time.zone.local(2026, 2, 2, 0, 0, 0) do
        payload = FactCheckManagerApiService.build_post_payload(@edition, @user, "stub@email.com")

        expected_payload = { source_app: "publisher",
                             source_id: @edition.id,
                             source_title: "New Title",
                             source_url: "#{Plek.find('publisher')}/editions/#{@edition.id}",
                             requester_name: "Ben",
                             requester_email: "joe1@bloggs.com",
                             current_content: { body: "some body" },
                             previous_content: nil,
                             deadline: "2026-02-09",
                             recipients: ["stub@email.com"] }

        assert_equal expected_payload, payload
      end
    end

    should "include the previous_content if a published version of the edition exists" do
      edition1 = FactoryBot.create(:answer_edition, :published)
      edition2 = edition1.build_clone

      payload = FactCheckManagerApiService.build_post_payload(edition2, @user, "stub@email.com")
      expected_hash = { body: "some body" }
      assert_equal expected_hash, payload[:previous_content]
    end

    should "unpack multiple email addresses" do
      payload = FactCheckManagerApiService.build_post_payload(@edition, @user, "stub@email.com, stub2@email.com")

      expected_recipients = %w[stub@email.com stub2@email.com]
      assert_equal expected_recipients, payload[:recipients]
    end
  end
end
