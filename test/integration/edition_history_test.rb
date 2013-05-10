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
      visit "/admin/editions/#{@guide.id}"

      assert_equal [true, false],
                   page.all("#accordion div.accordion-body").map { |e| e['style'].include?("display: block") }
    end

    should "show all actions when the first edition title is clicked" do
      visit "/admin/editions/#{@guide.id}"
      click_on "Notes for edition 1"

      assert_equal [true, true],
                   page.all("#accordion div.accordion-body").map { |e| e['style'].include?("display: block") }
    end
  end
end
