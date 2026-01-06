require "integration_test_helper"

class EditPublishedEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
  end

  should "show common content-type fields" do
    published_edition = FactoryBot.create(:edition, :published, in_beta: true)
    visit edition_path(published_edition)

    assert page.has_css?("h3", text: "Title")
    assert page.has_css?("p", text: published_edition.title)
    assert page.has_css?("h3", text: "Meta tag description")
    assert page.has_css?("p", text: published_edition.overview)
    assert page.has_css?("h3", text: "Is this beta content?")
    assert page.has_css?("p", text: "Yes")

    published_edition.in_beta = false
    published_edition.save!(validate: false)
    visit edition_path(published_edition)

    assert page.has_css?("p", text: "No")
  end

  should "show body field" do
    published_edition = FactoryBot.create(:edition, :published)
    visit edition_path(published_edition)

    assert page.has_css?("h3", text: "Body")
    assert page.has_css?("div", text: published_edition.body)
  end

  should "show public change field" do
    published_edition = FactoryBot.create(:edition, :published)
    visit edition_path(published_edition)

    assert page.has_css?("h3", text: "Public change note")
    assert page.has_css?("p", text: "None added")

    published_edition.major_change = true
    published_edition.change_note = "Change note for test"
    published_edition.save!(validate: false)
    visit edition_path(published_edition)

    assert page.has_text?(published_edition.change_note)
  end

  should "not show the 'Resend fact check email' link and text" do
    published_edition = FactoryBot.create(:edition, :published)
    visit edition_path(published_edition)

    assert page.has_no_link?("Resend fact check email")
    assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
  end

  context "place edition" do
    should "show published place edition fields as read only" do
      published_place_edition = FactoryBot.create(
        :place_edition,
        :published,
        title: "Some test title",
        overview: "Some overview text",
        place_type: "Some place type",
        introduction: "Some introduction",
        more_information: "Some more info",
        need_to_know: "Some need info",
        in_beta: true,
      )

      visit edition_path(published_place_edition)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: published_place_edition.title)
      assert page.has_css?("h3", text: "Meta tag description")
      assert page.has_css?("p", text: published_place_edition.overview)
      assert page.has_css?("h3", text: "Places Manager service identifier")
      assert page.has_css?("p", text: published_place_edition.place_type)
      assert page.has_css?("h3", text: "Introduction")
      assert page.has_css?("p", text: published_place_edition.introduction)
      assert page.has_css?("h3", text: "Further information (optional)")
      assert page.has_css?("p", text: published_place_edition.more_information)
      assert page.has_css?("h3", text: "What you need to know (optional)")
      assert page.has_css?("p", text: published_place_edition.need_to_know)
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes")
      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      published_place_edition.in_beta = false
      published_place_edition.save!(validate: false)
      visit edition_path(published_place_edition)

      assert page.has_css?("p", text: "No")
    end

    should "show 'None added' for empty fields in place edition" do
      [nil, ""].each do |empty_value|
        empty_place_edition = FactoryBot.create(
          :place_edition,
          :published,
          overview: empty_value,
          place_type: empty_value,
          introduction: empty_value,
          more_information: empty_value,
          need_to_know: empty_value,
        )

        visit edition_path(empty_place_edition)

        assert page.has_css?("p", text: "None added", count: 6)
      end
    end
  end

  context "local transaction edition" do
    should "show published local transaction edition fields as read only" do
      local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
      scotland_availability = FactoryBot.build(:scotland_availability, authority_type: "devolved_administration_service", alternative_url: "https://www.google.com")
      wales_availability = FactoryBot.build(:wales_availability, authority_type: "unavailable")
      published_local_transaction_edition = FactoryBot.create(
        :local_transaction_edition,
        :published,
        title: "Some test title",
        lgsl_code: local_service.lgsl_code,
        panopticon_id: FactoryBot.create(:artefact).id,
        lgil_code: 23,
        cta_text: "Some cta text",
        introduction: "Some introduction",
        more_information: "Some more info",
        need_to_know: "Some need info",
        before_results: "Some above results",
        after_results: "Some below results",
        scotland_availability:,
        wales_availability:,
        in_beta: true,
      )

      visit edition_path(published_local_transaction_edition)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: published_local_transaction_edition.title)
      assert page.has_css?("h3", text: "LGSL code")
      assert page.has_css?("p", text: published_local_transaction_edition.lgsl_code)
      assert page.has_css?("h3", text: "LGIL code")
      assert page.has_css?("p", text: published_local_transaction_edition.lgil_code)
      assert page.has_css?("h3", text: "Introduction")
      assert page.has_css?("p", text: published_local_transaction_edition.introduction)
      assert page.has_css?("h3", text: "Further information (optional)")
      assert page.has_css?("p", text: published_local_transaction_edition.more_information)
      assert page.has_css?("h3", text: "What you need to know (optional)")
      assert page.has_css?("p", text: published_local_transaction_edition.need_to_know)
      assert page.has_css?("h3", text: "Above results content (optional)")
      assert page.has_css?("p", text: published_local_transaction_edition.before_results)
      assert page.has_css?("h3", text: "Below results content (optional)")
      assert page.has_css?("p", text: published_local_transaction_edition.after_results)
      assert page.has_css?("h3", text: "Northern Ireland")
      assert page.has_css?("p", text: "Service available from local council")
      assert page.has_css?("h3", text: "Scotland")
      assert page.has_css?("p", text: "Service available from devolved administration (or a similar service is available)")
      assert page.has_css?("h3", text: "URL of the devolved administration website page")
      assert page.has_css?("p", text: "https://www.google.com")
      assert page.has_css?("h3", text: "Wales")
      assert page.has_css?("p", text: "Service not available")
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes")
      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      published_local_transaction_edition.in_beta = false
      published_local_transaction_edition.save!(validate: false)
      visit edition_path(published_local_transaction_edition)

      assert page.has_css?("p", text: "No")
    end

    should "show 'None added' for empty fields in local transaction edition" do
      local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
      [nil, ""].each do |empty_value|
        empty_local_transaction_edition = FactoryBot.create(
          :local_transaction_edition,
          :published,
          lgsl_code: local_service.lgsl_code,
          panopticon_id: FactoryBot.create(:artefact).id,
          lgil_code: 35,
          cta_text: empty_value,
          introduction: empty_value,
          more_information: empty_value,
          need_to_know: empty_value,
          before_results: empty_value,
          after_results: empty_value,
        )

        visit edition_path(empty_local_transaction_edition)

        assert page.has_css?("p", text: "None added", count: 7)
      end
    end
  end

  context "guide edition" do
    should "show published guide edition fields as read only" do
      published_guide_edition = FactoryBot.create(
        :guide_edition,
        :published,
        title: "Some test title",
        overview: "Some overview text",
        hide_chapter_navigation: true,
        in_beta: true,
      )

      visit edition_path(published_guide_edition)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: published_guide_edition.title)
      assert page.has_css?("h3", text: "Meta tag description")
      assert page.has_css?("p", text: published_guide_edition.overview)
      assert page.has_css?(".govuk-heading-m", text: "Chapters")
      assert_not page.has_css?(".govuk-button", text: "Add new chapter")
      assert page.has_css?("h3", text: "Is every chapter part of a step by step?")
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes", count: 2)
    end

    should "show guide chapter list for guide edition if present" do
      published_guide_edition_with_parts = FactoryBot.create(
        :guide_edition_with_two_parts,
        :published,
        title: "Some test title",
        overview: "Some overview text",
        hide_chapter_navigation: true,
        in_beta: true,
      )

      visit edition_path(published_guide_edition_with_parts)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: published_guide_edition_with_parts.title)
      assert page.has_css?("h3", text: "Meta tag description")
      assert page.has_css?("p", text: published_guide_edition_with_parts.overview)
      assert page.has_css?(".govuk-heading-m", text: "Chapters")
      assert page.has_css?(".govuk-summary-list__row", text: "PART !")
      assert page.has_css?(".govuk-summary-list__row", text: "PART !!")
      assert page.has_css?(".govuk-summary-list__actions", text: "View", minimum: 2)
      assert_not page.has_css?(".govuk-button", text: "Add new chapter")
      assert page.has_css?("h3", text: "Is every chapter part of a step by step?")
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes", count: 2)
    end

    should "show View chapter page when View chapter link is clicked" do
      published_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :published)
      visit edition_path(published_guide_edition_with_parts)

      within all(".govuk-summary-list__row").last do
        click_link("View")
      end

      assert page.has_content?("View chapter")
      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: "PART !!")
      assert page.has_css?("h3", text: "Slug")
      assert page.has_css?("p", text: "part-two")
      assert page.has_css?("h3", text: "Body")
      assert page.has_css?("p", text: "This is some more version text.")
    end

    should "show 'None added' for empty fields in guide edition" do
      [nil, ""].each do |empty_value|
        empty_guide_edition = FactoryBot.create(:guide_edition, :published, overview: empty_value)
        visit edition_path(empty_guide_edition)

        assert page.has_css?("p", text: "None added", count: 2)
      end
    end
  end

  context "transaction edition" do
    should "show fields for transaction edition" do
      transaction_edition = FactoryBot.create(
        :transaction_edition,
        :published,
        title: "Edit page title",
        overview: "metatags",
        in_beta: true,
        introduction: "Transaction introduction",
        more_information: "Transaction more information",
        need_to_know: "Transaction need to",
        link: "https://continue.com",
        will_continue_on: "To be continued...",
        alternate_methods: "Method A or B",
        publish_at: nil,
      )

      visit edition_path(transaction_edition)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: transaction_edition.title)
      assert page.has_css?("h3", text: "Meta tag description")
      assert page.has_css?("p", text: transaction_edition.overview)
      assert page.has_css?("h3", text: "Introduction")
      assert page.has_css?("p", text: transaction_edition.introduction)
      assert page.has_css?("h3", text: "Start button text")
      assert page.has_css?("p", text: transaction_edition.start_button_text)
      assert page.has_css?("h3", text: "Text below the start button (optional)")
      assert page.has_css?("p", text: transaction_edition.will_continue_on)
      assert page.has_css?("h3", text: "Link to start of transaction")
      assert page.has_css?("p", text: transaction_edition.link)
      assert page.has_css?("h3", text: "More information (optional)")
      assert page.has_css?("p", text: transaction_edition.more_information)
      assert page.has_css?("h3", text: "Other ways to apply (optional)")
      assert page.has_css?("p", text: transaction_edition.alternate_methods)
      assert page.has_css?("h3", text: "What you need to know (optional)")
      assert page.has_css?("p", text: transaction_edition.need_to_know)
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes")
      assert page.has_css?("h3", text: "Public change note")
      assert page.has_css?("p", text: "None added")

      transaction_edition.in_beta = false
      transaction_edition.save!(validate: false)
      visit edition_path(transaction_edition)

      assert page.has_css?("p", text: "No")
    end

    should "show 'None added' for empty fields in transaction edition" do
      [nil, ""].each do |empty_value|
        empty_transaction_edition = FactoryBot.create(
          :transaction_edition,
          :published,
          overview: empty_value,
          introduction: empty_value,
          more_information: empty_value,
          need_to_know: empty_value,
          link: empty_value,
          will_continue_on: empty_value,
          alternate_methods: empty_value,
        )

        visit edition_path(empty_transaction_edition)

        assert page.has_css?("p", text: "None added", count: 8)
      end
    end
  end

  context "completed transaction edition" do
    should "show fields for completed transaction edition with no promotion" do
      completed_transaction_edition = FactoryBot.create(
        :completed_transaction_edition,
        :published,
        title: "Edit page title",
        overview: "metatags",
        body: "completed transaction body",
        presentation_toggles: { promotion_choice: { choice: "none", url: "", opt_in_url: "", opt_out_url: "" } },
        in_beta: true,
        publish_at: nil,
      )

      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Title")
      assert page.has_css?("p", text: completed_transaction_edition.title)
      assert page.has_css?("h3", text: "Meta tag description")
      assert page.has_css?("p", text: completed_transaction_edition.overview)
      assert page.has_css?("h3", text: "Promotion")
      assert page.has_css?("p", text: "None added", count: 2)
      assert page.has_css?("h3", text: "Is this beta content?")
      assert page.has_css?("p", text: "Yes")
      assert page.has_css?("h3", text: "Public change note")

      completed_transaction_edition.in_beta = false
      completed_transaction_edition.save!(validate: false)
      visit edition_path(completed_transaction_edition)

      assert page.has_css?("p", text: "No")
    end

    should "show fields for completed transaction edition with organ donation promotion" do
      completed_transaction_edition = FactoryBot.create(
        :completed_transaction_edition,
        :published,
        presentation_toggles: { promotion_choice: { choice: "organ_donor", url: "https://example.com", opt_in_url: "https://opt-in.com", opt_out_url: "https://opt-out.com" } },
      )

      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Promotion")
      assert page.has_css?("p", text: "Organ donation")
      assert page.has_css?("h3", text: "Promotion URL")
      assert page.has_css?("p", text: "https://example.com")
      assert page.has_css?("h3", text: "Opt-in URL")
      assert page.has_css?("p", text: "https://opt-in.com")
      assert page.has_css?("h3", text: "Opt-out URL")
      assert page.has_css?("p", text: "https://opt-out.com")
    end

    should "show fields for completed transaction edition with photo id promotion" do
      completed_transaction_edition = FactoryBot.create(
        :completed_transaction_edition,
        :published,
        presentation_toggles: { promotion_choice: { choice: "bring_id_to_vote", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
      )

      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Promotion")
      assert page.has_css?("p", text: "Bring photo ID to vote")
      assert page.has_css?("h3", text: "Promotion URL")
      assert page.has_css?("p", text: "https://example.com")
    end

    should "show fields for completed transaction edition with mot reminder promotion" do
      completed_transaction_edition = FactoryBot.create(
        :completed_transaction_edition,
        :published,
        presentation_toggles: { promotion_choice: { choice: "mot_reminder", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
      )

      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Promotion")
      assert page.has_css?("p", text: "MOT reminders")
      assert page.has_css?("h3", text: "Promotion URL")
      assert page.has_css?("p", text: "https://example.com")
    end

    should "show fields for completed transaction edition with electric vehicle promotion" do
      completed_transaction_edition = FactoryBot.create(
        :completed_transaction_edition,
        :published,
        presentation_toggles: { promotion_choice: { choice: "electric_vehicle", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
      )

      visit edition_path(completed_transaction_edition)

      assert page.has_css?("h3", text: "Promotion")
      assert page.has_css?("p", text: "Electric vehicles")
      assert page.has_css?("h3", text: "Promotion URL")
      assert page.has_css?("p", text: "https://example.com")
    end

    should "show 'None added' for empty fields in completed transaction edition" do
      [nil, ""].each do |empty_value|
        empty_completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :published,
          overview: empty_value,
          presentation_toggles: { promotion_choice: { choice: "none" } },
        )

        visit edition_path(empty_completed_transaction_edition)

        assert page.has_css?("p", text: "None added", count: 3)
      end
    end
  end

  context "user is a govuk_editor" do
    setup do
      @published_edition = FactoryBot.create(:edition, :published)
    end

    should "show a 'create new edition' button when there isn't an existing draft edition" do
      visit edition_path(@published_edition)

      assert page.has_button?("Create new edition")
      assert page.has_no_link?("Edit latest edition")
    end

    should "show an 'edit latest edition' link when there is an existing draft edition" do
      FactoryBot.create(:edition, :draft, panopticon_id: @published_edition.artefact.id)

      visit edition_path(@published_edition)

      assert page.has_no_button?("Create new edition")
      assert page.has_link?("Edit latest edition")
    end
  end

  context "user is a welsh_editor" do
    setup do
      login_as_welsh_editor
    end

    context "viewing a welsh edition" do
      setup do
        @welsh_published_edition = FactoryBot.create(:edition, :published, :welsh)
      end

      should "show a 'create new edition' button when there isn't an existing draft edition" do
        visit edition_path(@welsh_published_edition)

        assert page.has_button?("Create new edition")
        assert page.has_no_link?("Edit latest edition")
      end

      should "show an 'edit latest edition' link when there is an existing draft edition" do
        FactoryBot.create(:edition, :draft, panopticon_id: @welsh_published_edition.artefact.id)
        visit edition_path(@welsh_published_edition)

        assert page.has_no_button?("Create new edition")
        assert page.has_link?("Edit latest edition")
      end
    end

    context "viewing a non-welsh edition" do
      setup do
        @non_welsh_published_edition = FactoryBot.create(:edition, :published)
      end

      should "not show a 'create new edition' button when there isn't an existing draft edition" do
        visit edition_path(@non_welsh_published_edition)

        assert page.has_no_button?("Create new edition")
        assert page.has_no_link?("Edit latest edition")
      end

      should "not show an 'edit latest edition' link when there is an existing draft edition" do
        FactoryBot.create(:edition, :draft, panopticon_id: @non_welsh_published_edition.artefact.id)
        visit edition_path(@non_welsh_published_edition)

        assert page.has_no_button?("Create new edition")
        assert page.has_no_link?("Edit latest edition")
      end
    end
  end

  context "user does not have editor permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Non Editor"))
      @published_edition = FactoryBot.create(:edition, :published)
    end

    should "not show a 'create new edition' button when there isn't an existing draft edition" do
      visit edition_path(@published_edition)

      assert page.has_no_button?("Create new edition")
      assert page.has_no_link?("Edit latest edition")
    end

    should "not show an 'edit latest edition' link when there is an existing draft edition" do
      FactoryBot.create(:edition, :draft, panopticon_id: @published_edition.artefact.id)
      visit edition_path(@published_edition)

      assert page.has_no_button?("Create new edition")
      assert page.has_no_link?("Edit latest edition")
    end
  end

  should "show a 'view on GOV.UK' link" do
    published_edition = FactoryBot.create(:edition, :published)
    visit edition_path(published_edition)

    assert page.has_link?("View on GOV.UK (opens in new tab)", href: "#{Plek.website_root}/#{published_edition.slug}")
  end
end
