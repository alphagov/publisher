#encoding: utf-8
require 'integration_test_helper'

class SimpleSmartAnswersTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
      :slug => "can-i-get-a-driving-licence",
      :kind => "simple_smart_answer",
      :owning_app => "publisher",
      :name => "Can I get a driving licence?"
    )

    setup_users
  end

  context "creating a new edition" do
    setup do
      visit "/admin/publications/#{@artefact.id}"
    end

    should "show the smart answer builder form with an initial question" do
      within ".page-header" do
        assert page.has_content? "Viewing “Can I get a driving licence?”"
      end

      assert page.has_css?(".nodes .node", count: 1)
      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_no_css?(".nodes .outcome")

      within ".builder-container" do
        assert page.has_content? "Question 1"

        assert page.has_button? "Add question"
        assert page.has_button? "Add outcome"
      end
    end

    should "allow additional nodes to be added" do
      click_on "Add question"
      assert page.has_css?(".nodes .node", count: 2)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_no_css?(".nodes .outcome")

      within ".nodes .question:nth-child(2)" do
        assert page.has_content?("Question 2")
        assert page.has_field?("title")
        assert page.has_field?("description")
      end

      click_on "Add outcome"
      assert page.has_css?(".nodes .node", count: 3)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 1)

      within ".nodes .outcome" do
        assert page.has_content?("Outcome 1")
        assert page.has_field?("title")
        assert page.has_field?("description")
      end
    end

    should "update the nodes json when the smart answer flow is changed" do
      within ".nodes .question:first-child" do
        fill_in "title", :with => ""
      end

      json = '{"question1":{"title":"","body":"","options":{}}}'
      save_page
      assert page.has_field?("edition[nodes_as_json]", :with => json )
    end

    # should "save the edition" do
    #   click_on "Save"
    #   assert page.has_content? "Simple smart answer edition was successfully updated."
    # end
  end

  # context "given an edition exists" do
  #   setup do
  #     @edition = FactoryGirl.create(:simple_smart_answer_edition, :panopticon_id => @artefact)
  #   end

  #   context "building a simple smart answer" do
  #     setup do
  #       visit "/admin/editions/#{@edition.id}"
  #     end

  #     should "add new questions" do
  #       within ".builder-container" do

  #       end
  #     end

  #     should "add new outcomes" do

  #     end

  #     # should ""
  #   end
  # end
end
