require "integration_test_helper"

class EditArchivedEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    @archived_edition = FactoryBot.create(:edition, :archived)
  end

  should "show a message when all editions are unpublished" do
    published_edition = FactoryBot.create(:edition, :published)
    new_edition = FactoryBot.create(
      :edition,
      :draft,
      panopticon_id: published_edition.artefact.id,
    )
    new_edition.artefact.state = "archived"
    new_edition.artefact.save!

    visit edition_path(new_edition)

    assert page.has_text?("This content has been unpublished and is no longer available on the website. All editions have been archived.")
  end

  should "not show the sidebar" do
    visit edition_path(@archived_edition)
    assert page.has_no_css?(".sidebar-components")
  end

  should "show common content-type fields" do
    archived_edition = FactoryBot.create(:edition, :archived, in_beta: true)
    visit edition_path(archived_edition)

    assert page.has_css?("h3", text: "Title")
    assert page.has_css?("p", text: archived_edition.title)
    assert page.has_css?("h3", text: "Meta tag description")
    assert page.has_css?("p", text: archived_edition.overview)
    assert page.has_css?("h3", text: "Is this beta content?")
    assert page.has_css?("p", text: "Yes")

    archived_edition.in_beta = false
    archived_edition.save!(validate: false)
    visit edition_path(archived_edition)

    assert page.has_css?("p", text: "No")
  end

  should "show body field" do
    visit edition_path(@archived_edition)

    assert page.has_css?("h3", text: "Body")
    assert page.has_css?("div", text: @archived_edition.body)
  end

  should "show public change field" do
    visit edition_path(@archived_edition)

    assert page.has_css?("h3", text: "Public change note")
    assert page.has_css?("p", text: "None added")

    @archived_edition.major_change = true
    @archived_edition.change_note = "Change note for test"
    @archived_edition.save!(validate: false)
    visit edition_path(@archived_edition)

    assert page.has_text?(@archived_edition.change_note)
  end

  should "not show the 'Resend fact check email' link and text" do
    visit edition_path(@archived_edition)

    assert page.has_no_link?("Resend fact check email")
    assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
  end

  context "guide edition" do
    setup do
      @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :archived)
      visit edition_path(@draft_guide_edition_with_parts)
    end

    should "not show 'Add new chapter' button" do
      assert_not page.has_css?(".govuk-button", text: "Add a new chapter")
    end

    should "not show 'Reorder chapters' button even with two parts present" do
      assert page.has_no_link?("Reorder chapters")
    end

    should "not allow user to load reorder chapters page" do
      visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

      assert current_path == edition_path(@draft_guide_edition_with_parts)
      assert page.has_content?("You are not allowed to perform this action in the current state.")
    end
  end
end
