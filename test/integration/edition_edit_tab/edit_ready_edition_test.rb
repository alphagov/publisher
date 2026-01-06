require "integration_test_helper"

class EditReadyEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    @ready_edition = FactoryBot.create(:edition, :ready)

    visit edition_path(@ready_edition)
  end

  context "user is a govuk editor" do
    should "show a 'Schedule' button in the sidebar" do
      assert page.has_link?("Schedule")
    end

    should "navigate to the 'Schedule publication' page when the 'Schedule' button is clicked" do
      click_link("Schedule")
      assert_current_path schedule_page_edition_path(@ready_edition.id)
    end

    should "show Preview link" do
      assert page.has_link?("Preview (opens in new tab)")
    end

    should "show the 'Fact check' button" do
      assert page.has_link?("Fact check", href: send_to_fact_check_page_edition_path(@ready_edition))
    end

    should "show the 'Request amendments' link" do
      assert page.has_link?("Request amendments")
    end

    should "navigate to the 'Request amendments' page when the link is clicked" do
      click_link("Request amendments")
      assert_current_path request_amendments_page_edition_path(@ready_edition.id)
    end

    should "not show the 'Resend fact check email' link and text" do
      assert page.has_no_link?("Resend fact check email")
      assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
    end

    should "show the 'Publish' button" do
      visit edition_path(@ready_edition)
      assert page.has_link?("Publish", href: send_to_publish_page_edition_path(@ready_edition))
    end
  end

  context "user is not a govuk editor" do
    setup do
      login_as(FactoryBot.create(:user))
      visit edition_path(@ready_edition)
    end

    should "not show any editable components" do
      assert page.has_no_css?(".govuk-textarea")
      assert page.has_no_css?(".govuk-input")
      assert page.has_no_css?(".govuk-radios")
    end

    should "not show the Save button" do
      assert page.has_no_button?("Save")
    end

    should "show the Preview link" do
      assert page.has_link?("Preview (opens in new tab)")
    end

    should "not show the 'Request amendments' link" do
      assert page.has_no_link?("Request amendments")
    end

    should "not show a 'Schedule' button in the sidebar" do
      assert page.has_no_button?("Schedule")
    end

    should "not show the 'Fact check' button" do
      assert page.has_no_link?("Fact check", href: send_to_fact_check_page_edition_path(@ready_edition))
    end

    should "not show the 'Publish' button" do
      assert_not page.has_link?("Publish", href: send_to_publish_page_edition_path(@ready_edition))
    end
  end

  context "edition is welsh" do
    setup do
      @welsh_edition = FactoryBot.create(:edition, :welsh, :ready)
    end

    context "user is a welsh editor" do
      setup do
        login_as_welsh_editor
        visit edition_path(@welsh_edition)
      end

      should "show a 'Schedule' button in the sidebar" do
        assert page.has_link?("Schedule")
      end

      should "navigate to the 'Schedule publication' page when the 'Schedule' button is clicked" do
        click_link("Schedule")
        assert_current_path schedule_page_edition_path(@welsh_edition.id)
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

      should "show the 'Publish' button" do
        assert page.has_link?("Publish", href: send_to_publish_page_edition_path(@welsh_edition))
      end
    end

    context "user is not a welsh editor" do
      setup do
        login_as(FactoryBot.create(:user))
        visit edition_path(@welsh_edition)
      end

      should "not show a 'Schedule' button in the sidebar" do
        assert page.has_no_button?("Schedule")
      end

      should "not show the 'Fact check' button" do
        assert page.has_no_link?("Fact check", href: send_to_fact_check_page_edition_path(@welsh_edition))
      end
    end
  end
end
