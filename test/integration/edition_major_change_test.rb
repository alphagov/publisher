require 'integration_test_helper'

class EditionMajorChangeTest < JavascriptIntegrationTest

  setup do
    setup_users
    stub_collections
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "doesn't show change note until an edition has been published" do
    edition = FactoryGirl.create(:answer_edition)
    visit_edition edition
    refute page.has_field?("edition_change_note")
    refute page.has_field?("edition_major_change")
  end

  context "change note fields" do
    setup do
      @edition = FactoryGirl.create(:answer_edition, state: 'published')
    end

    should "show change note fields once an edition has been published" do
      visit_edition @edition
      assert page.has_field?("edition_change_note")
      assert page.has_field?("edition_major_change")
    end

    context "for an edition in a published series" do
      setup do
        @second_edition = @edition.build_clone
        @second_edition.update_attributes(body: "Some different body text", state: "draft")
      end

      should "be visible" do
        visit_edition @second_edition
        assert page.has_field?("edition_change_note")
        assert page.has_field?("edition_major_change")
      end

      should "validate that the change note is present for a major change" do
        visit_edition @second_edition
        check("edition_major_change")
        save_edition

        within(".alert") do
          assert page.has_content?("We had some problems saving. Please check the form below.")
        end
        within("#edition_change_note_input .help-block") do
          assert page.has_content?("can't be blank")
        end

        fill_in "edition_change_note", with: "Something changed"
        save_edition

        within(".alert") do
          assert page.has_content?("edition was successfully updated.")
        end
      end
    end
  end
end

