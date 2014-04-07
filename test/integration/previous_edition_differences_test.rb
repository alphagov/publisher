require 'integration_test_helper'

class PreviousEditionDifferencesTest < JavascriptIntegrationTest
  setup do
    setup_users
    @first_edition = FactoryGirl.create(:answer_edition,
                                        :state => "published",
                                        :body => "test body 1")
  end

  context "First edition" do
    should "not have a link to show changes" do
      visit "/editions/#{@first_edition.id}"
      click_on "History & Notes"

      assert page.has_no_link?("Changes since previous edition")
    end
  end

  context "Subsequent editions" do
    setup do
      @second_edition = @first_edition.build_clone(AnswerEdition)
      @second_edition.body = "Test Body 2"
      @second_edition.save
      @second_edition.reload

      visit "/editions/#{@second_edition.id}"
      click_on "History & Notes"
    end

    should "have links to show changes since previous edition" do
      assert page.has_link?("Notes for edition 2")
      assert page.has_link?("Changes since previous edition")

      assert page.has_link?("Notes for edition 1")
    end

    should "show what the body differences are" do
      click_on "Changes since previous edition"

      assert page.has_content?("Changes from edition 1 to edition 2")
      assert page.has_content?("test body 1")
      assert page.has_content?("Test Body 2")
    end

    should "have a link back to the current edition" do
      click_on "Changes since previous edition"

      assert page.has_link?("Back to current edition", href: edition_path(@second_edition))
    end
  end
end
