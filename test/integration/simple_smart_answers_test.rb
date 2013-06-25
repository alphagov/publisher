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

        assert page.has_link? "Add question"
        assert page.has_link? "Add outcome"
      end
    end

    should "allow additional nodes to be added" do
      click_on "Add question"
      assert page.has_css?(".nodes .node", count: 2)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_no_css?(".nodes .outcome")

      within ".nodes .question:nth-child(2)" do
        assert page.has_content?("Question 2")
        assert page.has_selector?("input.node-title")
        assert page.has_selector?("input.node-body")
      end

      click_on "Add outcome"
      assert page.has_css?(".nodes .node", count: 3)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 1)

      within ".nodes .outcome" do
        assert page.has_content?("Outcome 1")
        assert page.has_selector?("input.node-title")
        assert page.has_selector?("input.node-body")
      end
    end

    should "set the slug and kind for a node" do
      click_on "Add question"

      within ".nodes .question:nth-child(2)" do
        assert_equal "question-2", find(:css, 'input.node-slug').value
        assert_equal "question", find(:css, 'input.node-kind').value
      end

      click_on "Add outcome"

      within ".nodes .outcome:nth-child(3)" do
        assert_equal "outcome-1", find(:css, 'input.node-slug').value
        assert_equal "outcome", find(:css, 'input.node-kind').value
      end

      click_on "Add question"

      within ".nodes .question:nth-child(4)" do
        assert_equal "question-3", find(:css, 'input.node-slug').value
        assert_equal "question", find(:css, 'input.node-kind').value
      end
    end

    should "not show options for a outcome" do
      click_on "Add outcome"

      within ".nodes .outcome" do
        assert page.has_no_selector?(".options")
        assert page.has_no_link?("Add an option")
        assert page.has_no_select?("next-node-list")
      end
    end

    should "build an initial option for a question" do
      click_on "Add question"

      within ".nodes .question:nth-child(2)" do
        assert page.has_selector?(".options")
        assert page.has_css?(".options .option", count: 1)
      end
    end

    should "allow additional options to be added for a question" do
      click_on "Add question"

      within ".nodes .question:nth-child(2)" do
        click_on "Add an option"

        assert page.has_selector?(".options")
        assert page.has_css?(".options .option", count: 2)
      end
    end

    should "show a list of subsequent nodes in the select box" do
      click_on "Add question"
      click_on "Add outcome"

      find(:css, ".nodes .question:nth-child(2) input.node-title").set("Label for Question Two")
      find(:css, ".nodes .outcome input.node-title").set("Label for Outcome One")

      within ".nodes .question:first-child" do
        assert page.has_select?("next-node-list", :options => ["Select a node..", "Question 2 (Label for Question Two)", "Outcome 1 (Label for Outcome One)"])
      end

      within ".nodes .question:nth-child(2)" do
        assert page.has_select?("next-node-list", :options => ["Select a node..", "Outcome 1 (Label for Outcome One)"])
      end
    end

    should "set the next node id from the select box" do
      click_on "Add outcome"
      find(:css, ".nodes .outcome input.node-title").set("Label for Outcome One")

      within ".nodes .question:first-child .option:first-child" do
        select "Outcome 1 (Label for Outcome One)", :from => "next-node-list"
        assert_equal "outcome-1", find(:css, 'input.next-node-id').value

        select "Select a node..", :from => "next-node-list"
        assert_equal "", find(:css, 'input.next-node-id').value
      end
    end

    should "persist a valid smart answer" do
      within ".nodes .question:first-child" do
        find(:css, "input.node-title").set("Which driving licence do you hold?")
        find(:css, "input.node-body").set("The type of driving licence you hold determines what vehicles you can drive.")
      end

      click_on "Add question"
      within ".nodes .question:nth-child(2)" do
        find(:css, "input.node-title").set("When did you get your licence?")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(3)" do
        find(:css, "input.node-title").set("You can only drive a car with an accompanying adult.")
        find(:css, "input.node-body").set("The adult must be over 21 years of age. You can't drive on the motorway.")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(4)" do
        find(:css, "input.node-title").set("You can drive all the things.")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(5)" do
        find(:css, "input.node-title").set("You can drive some of the things.")
      end

      # add the options
      within ".nodes .question:first-child .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Full licence")
          select "Question 2 (When did you get your licence?)", :from => "next-node-list"
        end

        click_on "Add an option"

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("Provisional licence")
          select "Outcome 1 (You can only drive a car with an accompanying adult.)", :from => "next-node-list"
        end
      end

      # add the options
      within ".nodes .question:nth-child(2) .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Recently")
          select "Outcome 2 (You can drive all the things.)", :from => "next-node-list"
        end

        click_on "Add an option"

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("A long time ago")
          select "Outcome 3 (You can drive some of the things.)", :from => "next-node-list"
        end
      end

      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 3)
      assert page.has_css?(".nodes .node", count: 5)

      click_on "Save"

      assert page.has_content?("Simple smart answer edition was successfully updated.")

      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 3)
      assert page.has_css?(".nodes .node", count: 5)
    end
  end
end
