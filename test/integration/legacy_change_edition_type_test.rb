require "legacy_integration_test_helper"

class LegacyChangeEditionTypeTest < LegacyIntegrationTest
  setup do
    stub_linkables
    FactoryBot.create(:user, :govuk_editor)
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  FULLY_TRANSITIONED_TYPES = %w[answer help_page place transaction completed_transaction local_transaction].freeze

  def select_target_edition(format)
    select(format.to_s.humanize, from: "to")
  end

  def edition_parts(edition)
    Set.new(edition.parts.map { |part| part.attributes.slice("title", "body", "slug") })
  end

  def create_artefact_of_kind(kind)
    case kind
    when "help_page"
      FactoryBot.create(:artefact, slug: "help/foo", kind:)
    when "completed_transaction"
      FactoryBot.create(:artefact, slug: "done/foo", kind:)
    else
      FactoryBot.create(:artefact, kind:)
    end
  end

  Edition.convertible_formats.permutation(2).each do |to, from|
    next if FULLY_TRANSITIONED_TYPES.include?(from)

    should "be able to convert #{from} into #{to}" do
      factory_name = "#{from}_edition".to_sym
      artefact = create_artefact_of_kind(from)
      edition = FactoryBot.create(factory_name, state: "published", panopticon_id: artefact.id)

      visit "/editions/#{edition.to_param}/admin"

      select_target_edition(to)

      click_on "Change format"

      assert_text edition.title
      assert_text "New edition created"
    end
  end
end
