require "integration_test_helper"

class ChangeEditionTypeTest < IntegrationTest
  setup do
    stub_linkables
    FactoryBot.create(:user, :govuk_editor)
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  NON_TRANSITIONED_TYPES = %w[guide simple_smart_answer].freeze

  Edition.convertible_formats.permutation(2).each do |to, from|
    next if NON_TRANSITIONED_TYPES.include?(from)

    should "be able to convert #{from} into #{to}" do
      factory_name = "#{from}_edition".to_sym
      edition = FactoryBot.create(factory_name, :published)

      visit "/editions/#{edition.to_param}/admin"
      choose to.humanize
      click_on "Save"

      assert_text edition.title
      assert_text "New edition created"
    end
  end
end
