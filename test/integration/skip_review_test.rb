#encoding: utf-8
require 'integration_test_helper'

class SkipReviewTest < JavascriptIntegrationTest
  setup do
    stub_linkables

    @artefact = FactoryGirl.create(:artefact,
                                    slug: "hedgehog-topiary",
                                    kind: "guide",
                                    name: "Foo bar",
                                    owning_app: "publisher")

    @guide = FactoryGirl.build(:guide_edition,
                               panopticon_id: @artefact.id,
                               title: "Foo bar",
                               state: "in_review",
                               review_requested_at: 1.hour.ago)
    @guide.parts.build(title: "Placeholder", body: "placeholder", slug: 'placeholder', order: 1)
    @guide.save!
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  should "allow a user with the correct permissions to force publish" do
    permitted_user = FactoryGirl.create(:user,
                                        name: "Vincent Panache",
                                        email: "test@example.com",
                                        permissions: ["skip_review"])


    login_as permitted_user

    visit "/publications/#{@artefact.id}"

    within(".alert .workflow-buttons") do
      assert page.has_content? "Skip review"
      click_on "Skip review"
    end

    # Fill out review modal
    fill_in "Comment", with: "Vincent Panache can skip reviews"
    click_button "Skip review"

    within(".page-title .label-info") do
      assert page.has_content? "Ready"
    end

    within(".workflow-buttons.navbar-btn") do
      assert page.has_css?(".btn-primary", text: "Publish")
    end
  end

  should "not allow a user without permissions to force publish" do
    editor = FactoryGirl.create(:user,
                                name: "Editor",
                                email: "thingy@example.com",
                                permissions: ["editor"])

    login_as editor

    visit "/publications/#{@artefact.id}"

    within(".alert .workflow-buttons") do
      assert page.has_no_content? "Skip review"
    end

    within(".workflow-buttons.navbar-btn") do
      assert page.has_css?(".btn-primary.disabled", text: "Publish")
    end
  end
end
