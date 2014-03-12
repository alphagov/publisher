require 'integration_test_helper'

class EditionHistoryTest < JavascriptIntegrationTest
  setup do
    setup_users
  end

  context "viewing the history and notes tab" do
    setup do
      @answer = FactoryGirl.create(:answer_edition, :state => "published")

      @answer.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "first"})
      @answer.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "second"})
      @answer.new_action(@author, Action::PUBLISH, {:comment => "third"})

      assert_equal ["first", "second", "third"], @answer.actions.map(&:comment)

      @guide = @answer.build_clone(GuideEdition)

      @guide.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "fourth"})
      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "fifth"})
      @guide.new_action(@author, Action::PUBLISH, {:comment => "sixth"})

      assert_equal ["fourth", "fifth", "sixth"], @guide.actions.map(&:comment)
    end

    should "have the first history actions visible" do
      visit "/editions/#{@guide.id}"

      assert_equal [true, false],
                   page.all("#edition-history div.accordion-body").map { |e| e['style'].include?("display: block") }
    end

    should "show all actions when the first edition title is clicked" do
      visit "/editions/#{@guide.id}"
      click_on "Notes for edition 1"

      assert_equal [true, true],
                   page.all("#edition-history div.accordion-body").map { |e| e['style'].include?("display: block") }
    end

    context "Important note" do
      should "be able to add a note" do
        visit "/editions/#{@guide.id}"
        click_on "History & Notes"
        fill_in "Important note", with: "This is an important note. Take note."
        click_on "Save important note"

        visit "/editions/#{@guide.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "History & Notes"
        assert_equal "This is an important note. Take note.",
                     page.find_field("edition_important_note").value
      end

      should "not be carried forward to new editions" do
        @edition = FactoryGirl.create(:answer_edition,
                                      :important_note => "This is an important note. Take note.",
                                      :state => "published")

        visit "/editions/#{@edition.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "Create new edition"
        assert page.has_no_content? "This is an important note. Take note."

        click_on "History & Notes"
        assert_equal "", page.find_field("edition_important_note").value
      end
    end
  end
end
