require "legacy_integration_test_helper"

class SimpleSmartAnswersTest < LegacyJavascriptIntegrationTest
  setup do
    @artefact = FactoryBot.create(
      :artefact,
      slug: "can-i-get-a-driving-licence",
      kind: "simple_smart_answer",
      owning_app: "publisher",
      name: "Can I get a driving licence?",
    )

    setup_users
    GDS::SSO.test_user = @author
    stub_linkables
    stub_holidays_used_by_fact_check
    stub_events_for_all_content_ids
    stub_users_from_signon_api
    UpdateWorker.stubs(:perform_async)
  end

  # fill_in does not trigger 'change' events until the element loses focus
  # so emulate a click elsewhere on the page.
  # https://github.com/teamcapybara/capybara/issues/620
  def unfocus
    page.find("body").click
  end

  context "creating a new edition" do
    setup do
      visit "/publications/#{@artefact.id}"
    end

    should "show the smart answer builder form with an initial question" do
      within ".page-title" do
        assert page.has_content? "Can I get a driving licence?"
      end

      assert page.has_css?(".nodes .node", count: 1)
      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_no_css?(".nodes .outcome")

      within ".builder-container" do
        assert page.has_content? "Start now"
        assert page.has_checked_field? "edition_start_button_text_start_now"
        ["Continue", "Find contact details", "Next"].each do |option|
          assert page.has_unchecked_field? "edition_start_button_text_#{option.tr(' ', '_').underscore}"
        end

        assert page.has_content? "Question 1"

        assert page.has_link? "Add question"
        assert page.has_link? "Add outcome"
      end
    end

    should "allow additional nodes to be added" do
      click_link("Add question")
      assert page.has_css?(".nodes .node", count: 2)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_no_css?(".nodes .outcome")

      within ".nodes .question:nth-child(2)" do
        assert page.has_content?("Question 2")
        assert page.has_selector?("input.node-title[placeholder='The title of the question']")
        assert page.has_selector?("textarea.node-body")
      end

      click_link("Add outcome")
      assert page.has_css?(".nodes .node", count: 3)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 1)

      within ".nodes .outcome" do
        assert page.has_content?("Outcome 1")
        assert page.has_content?("Title")
        assert page.has_selector?("textarea.node-body")
      end
    end

    should "add a question after other questions and before outcomes" do
      click_link("Add outcome")
      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        assert_equal "question-2", find(:css, "input.node-slug", visible: false).value
        assert_equal "2", find(:css, "input.node-order", visible: false).value
      end
    end

    should "add a question before outcomes when no other questions" do
      within ".nodes .question:nth-child(1)" do
        click_link(class: "remove-node")
      end

      click_link("Add outcome")
      click_link("Add question")

      within ".nodes .question:nth-child(1)" do
        assert_equal "question-2", find(:css, "input.node-slug", visible: false).value
        assert_equal "1", find(:css, "input.node-order", visible: false).value
      end
    end

    should "reorder questions when a question is added" do
      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        assert_equal "2", find(:css, "input.node-order", visible: false).value
      end

      within ".nodes .question:nth-child(1)" do
        find(".remove-node-label").click
      end

      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        assert_equal "1", find(:css, "input.node-order", visible: false).value
      end

      within ".nodes .question:nth-child(3)" do
        assert_equal "2", find(:css, "input.node-order", visible: false).value
      end
    end

    should "reorder outcomes after a question is added" do
      click_link("Add outcome")
      click_link("Add question")

      within ".nodes .outcome:nth-child(3)" do
        assert_equal "3", find(:css, "input.node-order", visible: false).value
      end
    end

    should "set the order for an outcome" do
      within ".nodes .question:nth-child(1)" do
        find(".remove-node-label").click
      end

      click_link("Add outcome")

      within ".nodes .outcome:nth-child(2)" do
        assert_equal "1", find(:css, "input.node-order", visible: false).value
      end

      click_link("Add outcome")

      within ".nodes .outcome:nth-child(3)" do
        assert_equal "2", find(:css, "input.node-order", visible: false).value
      end

      click_link("Add question")
      click_link("Add outcome")

      within ".nodes .outcome:nth-child(5)" do
        assert_equal "4", find(:css, "input.node-order", visible: false).value
      end
    end

    should "set the slug and kind for a node" do
      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        assert_equal "question-2", find(:css, "input.node-slug", visible: false).value
        assert_equal "question", find(:css, "input.node-kind", visible: false).value
      end

      click_link("Add question")

      within ".nodes .question:nth-child(3)" do
        assert_equal "question-3", find(:css, "input.node-slug", visible: false).value
        assert_equal "question", find(:css, "input.node-kind", visible: false).value
      end

      click_link("Add outcome")

      within ".nodes .outcome:nth-child(4)" do
        assert_equal "outcome-1", find(:css, "input.node-slug", visible: false).value
        assert_equal "outcome", find(:css, "input.node-kind", visible: false).value
      end
    end

    should "not show options for a outcome" do
      click_link("Add outcome")

      within ".nodes .outcome" do
        assert page.has_no_selector?(".options")
        assert page.has_no_link?("Add an option")
        assert page.has_no_select?("next-node-list")
      end
    end

    should "build an initial option for a question" do
      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        assert page.has_selector?(".options")
        assert page.has_css?(".options .option", count: 1)
      end
    end

    should "allow additional options to be added for a question" do
      click_link("Add question")

      within ".nodes .question:nth-child(2)" do
        click_link("Add answer")

        assert page.has_selector?(".options")
        assert page.has_css?(".options .option", count: 2)
      end
    end

    should "show a list of subsequent nodes in the select box" do
      click_link("Add question")
      click_link("Add outcome")

      within(".nodes .question:nth-child(2)") do
        question_title_element = find(:css, "input.node-title")
        fill_in(question_title_element[:id], with: "Label for Question Two")
      end

      within(".nodes .outcome") do
        outcome_title_element = find(:css, "input.node-title")
        fill_in(outcome_title_element[:id], with: "Label for Outcome One")
      end

      unfocus

      within ".nodes .question:first-child" do
        assert page.has_select?("next-node-list", options: ["Select a node..", "Question 2 (Label for Question Two)", "Outcome 1 (Label for Outcome One)"])
      end

      within ".nodes .question:nth-child(2)" do
        assert page.has_select?("next-node-list", options: ["Select a node..", "Outcome 1 (Label for Outcome One)"])
      end
    end

    should "set the next node id from the select box" do
      click_link("Add outcome")

      outcome_title_element = find(:css, ".nodes .outcome input.node-title")
      fill_in(outcome_title_element[:id], with: "Label for Outcome One")

      unfocus

      within ".nodes .question:first-child .option:first-child" do
        select "Outcome 1 (Label for Outcome One)", from: "next-node-list"
        assert_equal "outcome-1", find(:css, "input.next-node-id", visible: false).value

        select "Select a node..", from: "next-node-list"
        assert_equal "", find(:css, "input.next-node-id", visible: false).value
      end
    end

    should "raise appropriate validation errors" do
      find("#edition_title").set("")

      click_link("Add outcome")

      save_edition

      within "#error-summary" do
        assert page.has_content?("Enter a title")
        assert page.has_content?("Enter a label for Question 1, Option 1")
        assert page.has_content?("Enter a title for Outcome 1")
        assert page.has_content?("Enter a title for Question 1")
        assert page.has_content?("Select a node for Question 1, Option 1")
        assert_not page.has_content?("is invalid")
        assert_not page.has_content?("Slug can only consist of lower case characters, numbers and hyphens")
      end

      within ".nodes .question:first-child" do
        assert page.has_content?("Enter a title for Question 1")
        assert page.has_content?("Enter a label for Question 1, Option 1")
        assert page.has_content?("Select a node for Question 1, Option 1")
      end

      within ".nodes .outcome:nth-child(2)" do
        assert page.has_content?("Enter a title for Outcome 1")
      end
    end

    should "persist a valid smart answer" do
      within ".nodes .question:first-child" do
        find(:css, "input.node-title").set("Which driving licence do you hold?")
        find(:css, "textarea.node-body").set("The type of driving licence you hold determines what vehicles you can drive.")
      end

      click_link("Add question")
      within ".nodes .question:nth-child(2)" do
        find(:css, "input.node-title").set("When did you get your licence?")
      end

      click_link("Add outcome")
      within ".nodes .outcome:nth-child(3)" do
        find(:css, "input.node-title").set("You can only drive a car with an accompanying adult.")
        find(:css, "textarea.node-body").set("The adult must be over 21 years of age. You can't drive on the motorway.")
      end

      click_link("Add outcome")
      within ".nodes .outcome:nth-child(4)" do
        find(:css, "input.node-title").set("You can drive all the things.")
      end

      click_link("Add outcome")
      within ".nodes .outcome:nth-child(5)" do
        find(:css, "input.node-title").set("You can drive some of the things.")
      end

      # add the options
      within ".nodes .question:first-child .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Full licence")
          select "Question 2 (When did you get your licence?)", from: "next-node-list"
        end

        click_link("Add answer")

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("Provisional licence")
          select "Outcome 1 (You can only drive a car with an accompanying adult.)", from: "next-node-list"
        end
      end

      # add the options
      within ".nodes .question:nth-child(2) .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Recently")
          select "Outcome 2 (You can drive all the things.)", from: "next-node-list"
        end

        click_link("Add answer")

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("A long time ago")
          select "Outcome 3 (You can drive some of the things.)", from: "next-node-list"
        end
      end

      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 3)
      assert page.has_css?(".nodes .node", count: 5)

      save_edition

      assert page.has_content?("Simple smart answer edition was successfully updated.")

      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 3)
      assert page.has_css?(".nodes .node", count: 5)
    end

    should "preserve ordering of nodes when validation fails" do
      within ".nodes .question:first-child" do
        find(:css, "input.node-title").set("Do you hold a UK driving licence?")
      end

      click_link("Add outcome")
      within ".nodes .outcome:nth-child(2)" do
        find(:css, "input.node-title").set("You can't drive")
      end

      click_link("Add question")
      within ".nodes .question:nth-child(2)" do
        find(:css, "input.node-title").set("When did you get your licence?")
      end

      click_link("Add outcome")
      within ".nodes .outcome:nth-child(4)" do
        find(:css, "input.node-title").set("You can drive")
      end

      within ".nodes .question:nth-child(1) .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Yes")
          select "Select a node..", from: "next-node-list"
        end

        click_link("Add answer")

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("No")
          select "Select a node..", from: "next-node-list"
        end
      end

      save_edition
      page.has_content?("We had some problems saving. Please check the form below.")

      assert page.has_css?(".nodes .node", count: 4)

      within(".nodes") do
        within ".question:first-child" do
          assert page.has_selector?(".option:nth-child(1) .error select")
          assert page.has_selector?(".option:nth-child(1) .error select")
        end
        assert_equal "Do you hold a UK driving licence?", find(:css, ".node:nth-child(1) .node-title").value
        assert_equal "When did you get your licence?", find(:css, ".node:nth-child(2) .node-title").value
      end
    end
  end

  context "editing an existing edition" do
    setup do
      @edition = FactoryBot.build(
        :simple_smart_answer_edition,
        title: "Can I get a driving licence?",
        panopticon_id: @artefact.id,
        slug: "can-i-get-a-driving-licence",
        nodes: [],
      )
      @edition.nodes.build(
        slug: "question-1",
        order: 1,
        title: "To be or not to be?",
        kind: "question",
        options_attributes: [
          { label: "That is the question", next_node: "outcome-1" },
          { label: "That is not the question", next_node: "outcome-2" },
        ],
      )
      @edition.nodes.build(slug: "outcome-1", order: 2, title: "Outcome One", kind: "outcome")
      @edition.nodes.build(slug: "outcome-2", order: 3, title: "Outcome Two", kind: "outcome")
      @edition.save!
    end

    should "not save using ajax" do
      visit_edition @edition
      save_edition

      assert page.has_no_css?(".workflow-message", text: "Saving")
      assert page.has_no_css?(".workflow-message", text: "Saved")
    end

    should "correctly render the form" do
      visit_edition @edition

      within ".page-title" do
        assert page.has_content? "Can I get a driving licence?"
      end

      within ".builder-container" do
        assert page.has_css?(".nodes .node", count: 3)
        assert page.has_css?(".nodes .question", count: 1)
        assert page.has_css?(".nodes .outcome", count: 2)

        assert page.has_link? "Add question"
        assert page.has_link? "Add outcome"

        within ".nodes .node:first-child" do
          assert page.has_content?("Question 1")
          assert page.has_field?("edition_nodes_attributes_0_title", with: "To be or not to be?")

          assert page.has_css?(".option", count: 2)

          within ".options > div:nth-of-type(1)" do
            assert page.has_field?("edition_nodes_attributes_0_options_attributes_0_label", with: "That is the question")
            assert page.has_select?(
              "next-node-list",
              options: [
                "Select a node..",
                "Outcome 1 (Outcome One)",
                "Outcome 2 (Outcome Two)",
              ],
              selected: "Outcome 1 (Outcome One)",
            )
          end

          within ".options > div:nth-of-type(2)" do
            assert page.has_field?("edition_nodes_attributes_0_options_attributes_1_label", with: "That is not the question")
            assert page.has_select?(
              "next-node-list",
              options: ["Select a node..", "Outcome 1 (Outcome One)", "Outcome 2 (Outcome Two)"],
              selected: "Outcome 2 (Outcome Two)",
            )
          end
        end

        within ".nodes .node:nth-child(2)" do
          assert page.has_content?("Outcome 1")
          assert page.has_field?("edition_nodes_attributes_1_title", with: "Outcome One")

          assert page.has_no_css?(".options")
        end

        within ".nodes .node:nth-child(3)" do
          assert page.has_content?("Outcome 2")
          assert page.has_field?("edition_nodes_attributes_2_title", with: "Outcome Two")

          assert page.has_no_css?(".options")
        end
      end
    end

    should "delete an existing node and option" do
      visit_edition @edition

      within ".nodes .node:first-child .option:nth-child(2)" do
        click_link "Remove answer"
        assert_equal "1", page.find(:css, "#edition_nodes_attributes_0_options_attributes_1__destroy", visible: false).value
      end

      within ".nodes .outcome:nth-child(3)" do
        click_link("Remove outcome")
        assert_equal "1", page.find(:css, "#edition_nodes_attributes_2__destroy", visible: false).value
      end
      assert page.has_no_content?("Outcome 2")
      assert page.has_selector?(".nodes .outcome:nth-child(3)", visible: false)

      save_edition

      page.has_content?("Simple smart answer edition was successfully updated.")

      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_css?(".nodes .outcome", count: 1)
      assert page.has_css?(".nodes .node", count: 2)
    end

    should "reset the next node value in options when a node is deleted" do
      visit_edition @edition

      within ".nodes .outcome:nth-child(3)" do
        click_link "Remove outcome"
      end

      within ".nodes .node:first-child .option:nth-child(2)" do
        assert_equal "", page.find(:css, "#edition_nodes_attributes_0_options_attributes_1_next_node", visible: false).value
        assert page.has_select?(
          "next-node-list",
          options: ["Select a node..", "Outcome 1 (Outcome One)"],
          selected: "Select a node..",
        )
      end
    end

    should "correctly number new nodes" do
      @edition.nodes.where(slug: "outcome-2").first.update!(slug: "outcome-3")

      visit_edition @edition

      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_css?(".nodes .outcome", count: 2)

      click_link("Add outcome")

      within ".nodes .outcome:nth-child(4)" do
        assert_equal "outcome-4", find(:css, "input.node-slug", visible: false).value
        assert page.has_content?("Outcome 4")
      end
    end

    should "correctly order new nodes" do
      visit_edition @edition

      within ".nodes" do
        assert_equal "1", find(:css, ".node:nth-child(1) .node-order", visible: false).value
        assert_equal "2", find(:css, ".node:nth-child(2) .node-order", visible: false).value
        assert_equal "3", find(:css, ".node:nth-child(3) .node-order", visible: false).value
      end

      click_link("Add outcome")

      within ".nodes" do
        assert_equal "4", find(:css, ".node:nth-child(4) .node-order", visible: false).value
      end

      click_link("Add question")

      within ".nodes" do
        assert_equal "5", find(:css, ".node:nth-child(5) .node-order", visible: false).value
      end
    end

    should "highlight an error on the select field when the next node is blank" do
      visit_edition @edition

      within ".nodes .question:first-child .option:first-child" do
        select "Select a node..", from: "next-node-list"
        assert_equal "", find(:css, "input.next-node-id", visible: false).value
      end

      save_edition

      within ".nodes .question:first-child .option:first-child" do
        assert_equal "", find(:css, "input.next-node-id", visible: false).value
      end

      page.has_content?("We had some problems saving. Please check the form below.")

      within ".nodes .question:first-child .option:first-child" do
        assert page.has_selector?(".error select")
      end
    end
  end

  context "mermaid:" do
    setup do
      @edition = FactoryBot.build(
        :simple_smart_answer_edition,
        title: "Can I get a driving licence?",
        panopticon_id: @artefact.id,
        slug: "can-i-get-a-driving-licence",
        nodes: [],
      )
      @edition.nodes.build(
        slug: "question-1",
        order: 1,
        title: "To be or not to be?",
        kind: "question",
        options_attributes: [
          { label: "That is the question", next_node: "outcome-1" },
          { label: "That is not the question", next_node: "outcome-2" },
        ],
      )
      @edition.nodes.build(slug: "outcome-1", order: 2, title: "Outcome One", kind: "outcome")
      @edition.nodes.build(slug: "outcome-2", order: 3, title: "Outcome Two", kind: "outcome")
      @edition.save!
    end

    should "render small smart-answer flowchart successfully" do
      visit "/editions/#{@edition.to_param}/diagram"

      within ".nodes" do
        assert page.has_content? "Q1. To be or not to be?"
      end
    end

    should "render large smart-answer flowchart with 421 'edges' (i.e lines/arrows) successfully" do
      file = File.open(Rails.root.join("test/integration/large_SA_mermaid_code.txt").to_s)

      mermaid_code = file.read

      SimpleSmartAnswerEdition.any_instance.stubs(:generate_mermaid).returns(mermaid_code)

      visit "/editions/#{@edition.to_param}/diagram"

      within ".nodes" do
        assert page.has_content? "Q1. Which period do you want to calculate the fuel scale charge for?"
      end
    end
  end
end
