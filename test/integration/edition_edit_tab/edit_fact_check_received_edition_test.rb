require "integration_test_helper"

class EditFactCheckReceivedEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @fact_check_received_edition = FactoryBot.create(:edition, :fact_check_received)
  end

  context "when user has govuk editor permissions" do
    setup do
      visit edition_path(@fact_check_received_edition)
    end

    should "show Preview link" do
      assert page.has_link?("Preview (opens in new tab)")
    end

    should "show the fact check inset text" do
      assert page.has_text?("We have received a fact check response for this edition.")
      assert page.has_text?("Please check the response in History and notes and select an action below.")
    end

    should "show the 'Fact check' button" do
      visit edition_path(@fact_check_received_edition)

      assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(@fact_check_received_edition))
    end

    should "show the 'Request amendments' link" do
      assert page.has_link?("Request amendments")
    end

    should "navigate to the 'Request amendments' page when the link is clicked" do
      click_link("Request amendments")
      assert_current_path request_amendments_page_edition_path(@fact_check_received_edition.id)
    end

    should "show the 'No changes needed' link" do
      assert page.has_link?("No changes needed")
    end

    should "navigate to the 'Approve fact check' page when the link is clicked" do
      click_link("No changes needed")

      assert_current_path approve_fact_check_page_edition_path(@fact_check_received_edition.id)
    end

    should "not show the 'Resend fact check email' link and text" do
      assert page.has_no_link?("Resend fact check email")
      assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
    end
  end

  context "user does not have editor permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Non Editor"))
      visit edition_path(@fact_check_received_edition)
    end

    should "not show any editable components" do
      assert page.has_no_css?(".govuk-textarea")
      assert page.has_no_css?(".govuk-input")
      assert page.has_no_css?(".govuk-radios")
    end

    should "not show the Save button" do
      assert page.has_no_button?("Save")
    end

    should "not show the fact check inset text" do
      assert page.has_no_text?("We have received a fact check response for this edition./nPlease check the response in History & Notes, and select an action below.")
    end

    should "show the Preview link" do
      assert page.has_link?("Preview (opens in new tab)")
    end

    should "not show the 'Fact check' button" do
      assert page.has_no_link?("Fact check", href: send_to_fact_check_page_edition_path(@fact_check_received_edition))
    end

    should "not show the 'No changes needed' link" do
      assert page.has_no_link?("No changes needed")
    end

    should "not show the 'Request amendments' link" do
      assert page.has_no_link?("Request amendments")
    end
  end

  context "edition is welsh" do
    setup do
      @welsh_edition = FactoryBot.create(:edition, :fact_check_received, :welsh)
    end

    context "user is a welsh editor" do
      setup do
        login_as_welsh_editor
      end

      context "when viewing a welsh edition" do
        setup do
          visit edition_path(@welsh_edition)
        end

        should "show the 'Fact check' button" do
          assert @user.has_editor_permissions?(@welsh_edition)
          assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(@welsh_edition))
        end

        should "show the 'Request amendments' link" do
          assert page.has_link?("Request amendments")
        end

        should "navigate to the 'Request amendments' page when the link is clicked" do
          click_link("Request amendments")
          assert_current_path request_amendments_page_edition_path(@welsh_edition.id)
        end

        should "show the 'No changes needed' link" do
          assert page.has_link?("No changes needed")
        end

        should "navigate to the 'Approve fact check' page when the link is clicked" do
          click_link("No changes needed")
          assert_current_path approve_fact_check_page_edition_path(@welsh_edition.id)
        end
      end

      context "when viewing a non-welsh edition" do
        setup do
          visit edition_path(@fact_check_received_edition)
        end

        should "not show any editable components" do
          assert page.has_no_css?(".govuk-textarea")
          assert page.has_no_css?(".govuk-input")
          assert page.has_no_css?(".govuk-radios")
        end

        should "not show the Save button" do
          assert page.has_no_button?("Save")
        end

        should "not show the fact check inset text" do
          assert page.has_no_text?("We have received a fact check response for this edition./nPlease check the response in History & Notes, and select an action below.")
        end

        should "show the Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end

        should "not show the 'Fact check' button" do
          assert page.has_no_link?("Fact check", href: send_to_fact_check_page_edition_path(@fact_check_received_edition))
        end

        should "not show the 'No changes needed' link" do
          assert page.has_no_link?("No changes needed")
        end

        should "not show the 'Request amendments' link" do
          assert page.has_no_link?("Request amendments")
        end
      end
    end

    context "user is not a welsh editor" do
      setup do
        login_as(FactoryBot.create(:user))
        visit edition_path(@welsh_edition)
      end

      should "not show any editable components" do
        assert page.has_no_css?(".govuk-textarea")
        assert page.has_no_css?(".govuk-input")
        assert page.has_no_css?(".govuk-radios")
      end

      should "not show the Save button" do
        assert page.has_no_button?("Save")
      end

      should "not show the fact check inset text" do
        assert page.has_no_text?("We have received a fact check response for this edition./nPlease check the response in History & Notes, and select an action below.")
      end

      should "show the Preview link" do
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "not show the 'Fact check' button" do
        assert page.has_no_link?("Fact check", href: send_to_fact_check_page_edition_path(@fact_check_received_edition))
      end

      should "not show the 'No changes needed' link" do
        assert page.has_no_link?("No changes needed")
      end

      should "not show the 'Request amendments' link" do
        assert page.has_no_link?("Request amendments")
      end
    end
  end
end
