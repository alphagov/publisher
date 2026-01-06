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
end
