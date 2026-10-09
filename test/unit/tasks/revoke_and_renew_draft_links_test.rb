require "test_helper"
require "rake"

class RevokeAndRenewDraftLinksTest < ActiveSupport::TestCase
  setup do
    stub_request(:patch, %r{/api/requests/publisher/}).to_return(status: 200, body: "{}")
    @draft_edition = create_authed_edition
    @second_draft_edition = create_authed_edition
  end

  context "#fact_check:revoke_and_renew_draft_links" do
    should "clear the current auth_bypass_id for the given editions" do
      Rake::Task["fact_check:revoke_and_renew_draft_links"].reenable
      first_auth_bypass_id = @draft_edition.auth_bypass_id.to_s
      second_auth_bypass_id = @second_draft_edition.auth_bypass_id.to_s

      UpdateWorker.expects(:perform_async).with(@draft_edition.id.to_s)
      UpdateWorker.expects(:perform_async).with(@second_draft_edition.id.to_s)
      Rake::Task["fact_check:revoke_and_renew_draft_links"].invoke(@draft_edition.id.to_s, @second_draft_edition.id.to_s)

      @draft_edition.reload
      @second_draft_edition.reload

      assert_not_equal(first_auth_bypass_id, @draft_edition.auth_bypass_id.to_s)
      assert_not_equal(second_auth_bypass_id, @second_draft_edition.auth_bypass_id.to_s)
    end

    should "send the new auth_bypass_id to Fact Check Manager" do
      Rake::Task["fact_check:revoke_and_renew_draft_links"].reenable

      Rake::Task["fact_check:revoke_and_renew_draft_links"].invoke(@draft_edition.id.to_s)

      assert_requested :patch, %r{/api/requests/publisher/#{@draft_edition.id}},
                       body: hash_including(draft_auth_bypass_id: @draft_edition.reload.auth_bypass_id)
    end

    should "renew the draft link of an edition Fact Check Manager has no request for" do
      Rake::Task["fact_check:revoke_and_renew_draft_links"].reenable
      stub_request(:patch, %r{/api/requests/publisher/}).to_return(status: 404)
      auth_bypass_id = @draft_edition.auth_bypass_id

      assert_output(/has no Fact Check Manager request/) do
        Rake::Task["fact_check:revoke_and_renew_draft_links"].invoke(@draft_edition.id.to_s)
      end
      assert_not_equal auth_bypass_id, @draft_edition.reload.auth_bypass_id
    end

    should "renew the editions it finds, then exit listing the ids it cannot find" do
      Rake::Task["fact_check:revoke_and_renew_draft_links"].reenable
      missing_id = SecureRandom.uuid
      auth_bypass_id = @draft_edition.auth_bypass_id

      error = assert_raises(SystemExit) do
        Rake::Task["fact_check:revoke_and_renew_draft_links"].invoke(@draft_edition.id.to_s, missing_id)
      end
      assert_equal "No editions found for edition ids: #{missing_id}", error.message
      assert_not_equal auth_bypass_id, @draft_edition.reload.auth_bypass_id
    end
  end

  def create_authed_edition
    FactoryBot.create(:edition, :auth_bypass_id)
  end
end
