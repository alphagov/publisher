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
        assert page.has_selector?("input.node-title[placeholder='The title of the question']")
        assert page.has_selector?("textarea.node-body")
      end

      click_on "Add outcome"
      assert page.has_css?(".nodes .node", count: 3)
      assert page.has_css?(".nodes .question", count: 2)
      assert page.has_css?(".nodes .outcome", count: 1)

      within ".nodes .outcome" do
        assert page.has_content?("Outcome 1")
        assert page.has_selector?("input.node-title[placeholder='The title of the outcome']")
        assert page.has_selector?("textarea.node-body")
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
        find(:css, "textarea.node-body").set("The type of driving licence you hold determines what vehicles you can drive.")
      end

      click_on "Add question"
      within ".nodes .question:nth-child(2)" do
        find(:css, "input.node-title").set("When did you get your licence?")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(3)" do
        find(:css, "input.node-title").set("You can only drive a car with an accompanying adult.")
        find(:css, "textarea.node-body").set("The adult must be over 21 years of age. You can't drive on the motorway.")
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

    should "preserve ordering of nodes when validation fails" do
      within ".nodes .question:first-child" do
        find(:css, "input.node-title").set("Do you hold a UK driving licence?")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(2)" do
        find(:css, "input.node-title").set("You can't drive")
      end

      click_on "Add outcome"
      within ".nodes .outcome:nth-child(3)" do
        find(:css, "input.node-title").set("You can drive")
      end

      within ".nodes .question:nth-child(1) .options" do
        within ".option:first-child" do
          find(:css, "input.option-label").set("Yes")
          select "Select a node..", :from => "next-node-list"
        end

        click_on "Add an option"

        within ".option:nth-child(2)" do
          find(:css, "input.option-label").set("No")
          select "Select a node..", :from => "next-node-list"
        end
      end

      click_on "Save"
      
      wait_until {
        page.has_content?("We had some problems saving. Please check the form below.")
      }
      
      assert page.has_css?(".nodes .node", count: 3)
      
      within('.nodes') do
        within ".question:first-child" do
          assert page.has_selector?(".option:nth-child(1) .error select")
          assert page.has_selector?(".option:nth-child(1) .error select")
        end
        assert_equal "Do you hold a UK driving licence?", find(:css, '.node:nth-child(1) .node-title').value
      end

    end
  end

  context "editing an existing edition" do
    setup do
      @edition = FactoryGirl.build(:simple_smart_answer_edition,
        :title => "Can I get a driving licence?",
        :panopticon_id => @artefact.id,
        :slug => "can-i-get-a-driving-licence"
      )
      @edition.nodes.build(:slug => "question-1", :order => 1, :title => "To be or not to be?", :kind => "question", :options_attributes => [
        { :label => "That is the question", :next_node => "outcome-1" },
        { :label => "That is not the question", :next_node => "outcome-2" }
      ])
      @edition.nodes.build(:slug => "outcome-1", :order => 2, :title => "Outcome One", :kind => "outcome")
      @edition.nodes.build(:slug => "outcome-2", :order => 3, :title => "Outcome Two", :kind => "outcome")
      @edition.save!
    end

    should "correctly render the form" do
      visit "/admin/editions/#{@edition.id}"

      within ".page-header" do
        assert page.has_content? "Viewing “Can I get a driving licence?”"
      end

      within ".builder-container" do
        assert page.has_css?(".nodes .node", count: 3)
        assert page.has_css?(".nodes .question", count: 1)
        assert page.has_css?(".nodes .outcome", count: 2)

        assert page.has_link? "Add question"
        assert page.has_link? "Add outcome"

        within ".nodes .node:first-child" do
          assert page.has_content?("Question 1")
          assert page.has_field?("edition_nodes_attributes_0_title", :with => "To be or not to be?")

          assert page.has_css?(".option", count: 2)

          within ".options > div:nth-of-type(1)" do
            assert page.has_field?("edition_nodes_attributes_0_options_attributes_0_label", :with => "That is the question")
            assert page.has_select?("next-node-list",
              :options => ["Select a node..", "Outcome 1 (Outcome One)", "Outcome 2 (Outcome Two)"],
              :selected => "Outcome 1 (Outcome One)"
            )
          end

          within ".options > div:nth-of-type(2)" do
            assert page.has_field?("edition_nodes_attributes_0_options_attributes_1_label", :with => "That is not the question")
            assert page.has_select?("next-node-list",
              :options => ["Select a node..", "Outcome 1 (Outcome One)", "Outcome 2 (Outcome Two)"],
              :selected => "Outcome 2 (Outcome Two)"
            )
          end
        end

        within ".nodes .node:nth-child(2)" do
          assert page.has_content?("Outcome 1")
          assert page.has_field?("edition_nodes_attributes_1_title", :with => "Outcome One")

          assert page.has_no_css?(".options")
        end

        within ".nodes .node:nth-child(3)" do
          assert page.has_content?("Outcome 2")
          assert page.has_field?("edition_nodes_attributes_2_title", :with => "Outcome Two")

          assert page.has_no_css?(".options")
        end
      end
    end

    should "delete an existing node and option" do
      visit "/admin/editions/#{@edition.id}"

      within ".nodes .node:first-child .option:nth-child(2)" do
        click_link "Remove option"
        assert_equal "1", page.find_by_id('edition_nodes_attributes_0_options_attributes_1__destroy').value
      end

      within ".nodes .outcome:nth-child(3)" do
        click_link "Remove node"
        assert_equal "1", page.find_by_id('edition_nodes_attributes_2__destroy').value
      end
      assert page.has_selector?(".nodes .outcome:nth-child(3)", :visible => false)

      click_button "Save"

      wait_until {
        page.has_content?("Simple smart answer edition was successfully updated.")
      }

      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_css?(".nodes .outcome", count: 1)
      assert page.has_css?(".nodes .node", count: 2)
    end

    should "reset the next node value in options when a node is deleted" do
      visit "/admin/editions/#{@edition.id}"

      within ".nodes .outcome:nth-child(3)" do
        click_link "Remove node"
      end

      within ".nodes .node:first-child .option:nth-child(2)" do
        assert_equal "", page.find_by_id('edition_nodes_attributes_0_options_attributes_1_next_node').value
        assert page.has_select?("next-node-list",
          :options => ["Select a node..", "Outcome 1 (Outcome One)"],
          :selected => "Select a node.."
        )
      end
    end

    should "correctly number new nodes" do
      @edition.nodes.where(:slug => "outcome-2").first.update_attribute(:slug, "outcome-3")

      visit "/admin/editions/#{@edition.id}"

      assert page.has_css?(".nodes .question", count: 1)
      assert page.has_css?(".nodes .outcome", count: 2)

      click_on "Add outcome"

      within ".nodes .outcome:nth-child(4)" do
        assert_equal "outcome-4", find(:css, 'input.node-slug').value
        assert page.has_content?("Outcome 4")
      end
    end

    should "correctly order new nodes" do
      visit "/admin/editions/#{@edition.id}"

      within ".nodes" do
        assert_equal "1", find(:css, '.node:nth-child(1) .node-order').value
        assert_equal "2", find(:css, '.node:nth-child(2) .node-order').value
        assert_equal "3", find(:css, '.node:nth-child(3) .node-order').value
      end

      click_on "Add outcome"
      
      within ".nodes" do
        assert_equal "4", find(:css, '.node:nth-child(4) .node-order').value
      end

      click_on "Add question"

      within ".nodes" do
        assert_equal "5", find(:css, '.node:nth-child(5) .node-order').value
      end
    end

    should "highlight an error on the select field when the next node is blank" do
      visit "/admin/editions/#{@edition.id}"

      within ".nodes .question:first-child .option:first-child" do
        select "Select a node..", :from => "next-node-list"
        assert_equal "", find(:css, 'input.next-node-id').value
      end

      click_on "Save"
      
      within ".nodes .question:first-child .option:first-child" do
        assert_equal "", find(:css, 'input.next-node-id').value
      end

      wait_until {
        page.has_content?("We had some problems saving. Please check the form below.")
      }

      within ".nodes .question:first-child .option:first-child" do
        assert page.has_selector?(".error select")
      end
    end
  end
end
