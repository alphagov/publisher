require "test_helper"
require "support/fact_check_manager_api_helpers"
require "rake"

class RevokeAndRenewDraftLinksTest < ActiveSupport::TestCase
  setup do
    stub_patch_update_fact_check_content(success: true)
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
      Rake::Task["fact_check:revoke_and_renew_draft_links"].invoke("#{@draft_edition.id},#{@second_draft_edition.id}")

      @draft_edition.reload
      @second_draft_edition.reload

      assert_not_equal(first_auth_bypass_id, @draft_edition.auth_bypass_id.to_s)
      assert_not_equal(second_auth_bypass_id, @second_draft_edition.auth_bypass_id.to_s)
    end
  end

  def create_authed_edition
    FactoryBot.create(:edition, :auth_bypass_id)
  end
end
