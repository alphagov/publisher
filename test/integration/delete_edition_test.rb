require 'integration_test_helper'

class DeleteEditionTest < ActionDispatch::IntegrationTest

  setup do
    content_id = SecureRandom.uuid
    @artefact = FactoryGirl.create(:artefact,
      slug: "i-dont-want-this",
      content_id: content_id,
      kind: "guide",
      name: "Foo bar",
      owning_app: "publisher",
    )

    @edition = FactoryGirl.create(:guide_edition, panopticon_id: @artefact.id)

    setup_users
    stub_linkables
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "deleting a draft edition discards the draft in the publishing api" do
    visit "/editions/#{@edition.id}"

    click_on "Admin"

    Services.publishing_api.expects(:discard_draft).with(@artefact.content_id)

    click_button "Delete this edition – #1"

    within(".alert-success") do
      assert page.has_content?("Guide destroyed")
    end
  end
end
