require "legacy_integration_test_helper"

class ChangeEditionTypeTest < LegacyJavascriptIntegrationTest
  setup do
    stub_linkables
    FactoryBot.create(:user, :govuk_editor)
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  fully_transitioned_types = %w[answer help_page place transaction completed_transaction local_transaction]

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

  sample_parts = Set.new([
    {
      "title" => "PART !",
      "body" => "This is some edition version text.",
      "slug" => "part-one",
    },
    {
      "title" => "PART !!",
      "body" =>
    "This is some more edition version text.",
      "slug" => "part-two",
    },
  ])

  without_javascript do
    formats = Edition.convertible_formats - fully_transitioned_types
    conversions = formats.permutation(2).reject { |pair| pair[0] == pair[1] }

    conversions.each do |to, from|
      should "be able to convert #{from} into #{to}" do
        factory_name = "#{from}_edition".to_sym
        artefact = create_artefact_of_kind(from)
        edition = FactoryBot.create(factory_name, state: "published", panopticon_id: artefact.id)
        sample_parts.each { |part| edition.parts.create(part) } if edition.respond_to?(:parts)

        visit "/editions/#{edition.to_param}/admin"

        select_target_edition(to)

        click_on "Change format"

        assert_text edition.title
        assert_text "New edition created"

        edition_whole_body = edition.whole_body.gsub(/\s+/, " ").strip

        if edition.respond_to?(:parts)
          assert(sample_parts.subset?(edition_parts(edition)))
        else
          assert_selector("form#edition-form .well textarea", text: /\s*#{Regexp.quote(edition_whole_body)}\s*/, visible: true)
        end
      end
    end
  end
end
