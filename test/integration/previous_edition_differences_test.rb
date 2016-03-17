require 'integration_test_helper'

class PreviousEditionDifferencesTest < JavascriptIntegrationTest
  setup do
    stub_register_published_content
    setup_users
    stub_linkables
    @first_edition = FactoryGirl.create(:answer_edition,
                                        :state => "published",
                                        :body => "test body 1")
  end

  context "First edition" do
    should "not have a link to show changes" do
      visit "/editions/#{@first_edition.id}"
      click_on "History and notes"

      assert page.has_no_link?("Compare with previous")
    end
  end

  context "Subsequent editions" do
    setup do
      @second_edition = @first_edition.build_clone(AnswerEdition)
      @second_edition.update_attributes(body: "Test Body 2")
      @second_edition.reload

      visit "/editions/#{@second_edition.id}"
      click_on "History and notes"
    end

    should "have links to view the difference with the previous version" do
      assert page.has_link?("Edition 2")
      assert page.has_link?("Compare with edition 1")

      assert page.has_link?("Edition 1")
    end

    should "show what the body differences are" do
      click_on "Compare with edition 1"

      assert page.has_content?("Changes from edition 1 to edition 2")
      assert page.has_content?("test body 1")
      assert page.has_content?("Test Body 2")
    end

    should "have a link back to the current edition" do
      click_on "Compare with edition 1"

      assert page.has_link?("Back to current edition", href: edition_path(@second_edition))
    end
  end

  context "Editions scheduled for publishing" do
    setup do
      @second_edition = @first_edition.build_clone(AnswerEdition)
      @second_edition.update_attributes(body: "Test Body 2")
      @second_edition.update_attribute(:state, :scheduled_for_publishing)
    end

    should "show differences after publishing" do
      ScheduledPublisher.new.perform(@second_edition.id.to_s)

      @second_edition.reload
      assert_equal "published", @second_edition.state

      visit "/editions/#{@second_edition.id}"
      click_on "History and notes"
      click_on "Compare with edition 1"

      assert page.has_content?("test body 1")
      assert page.has_content?("Test Body 2")
    end
  end
end
