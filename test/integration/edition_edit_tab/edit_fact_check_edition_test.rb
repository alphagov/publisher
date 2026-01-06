require "integration_test_helper"

class EditFactCheckEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    @govuk_requester = FactoryBot.create(:user, :govuk_editor, name: "Stub requester")
    login_as(@govuk_editor)
    @test_strategy = Flipflop::FeatureSet.current.test!
    @test_strategy.switch!(:design_system_edit_phase_3a, true)
    @fact_check_edition = FactoryBot.create(:edition, :fact_check, requester: @govuk_editor)
  end

  should "show the 'Resend fact check email' link and text to govuk editors" do
    login_as(@govuk_editor)
    visit edition_path(@fact_check_edition)

    assert page.has_link?("Resend fact check email")
    assert page.has_text?("You've requested this edition to be fact checked. We're awaiting a response.")
  end

  should "show the requester specific text to govuk editors" do
    login_as(@govuk_editor)
    @fact_check_edition = FactoryBot.create(:edition, :fact_check, requester: @govuk_requester)

    visit edition_path(@fact_check_edition)

    assert page.has_text?("Stub requester requested this edition to be fact checked. We're awaiting a response.")
  end

  should "show Preview link" do
    visit edition_path(@fact_check_edition)
    assert page.has_link?("Preview (opens in new tab)")
  end

  should "show the 'Request amendments' link" do
    visit edition_path(@fact_check_edition)
    assert page.has_link?("Request amendments")
  end

  should "navigate to the 'Request amendments' page when the link is clicked" do
    visit edition_path(@fact_check_edition)
    click_link("Request amendments")

    assert_current_path request_amendments_page_edition_path(@fact_check_edition.id)
  end

  context "when a welsh editor" do
    setup do
      @welsh_editor = FactoryBot.create(:user, :welsh_editor, name: "Stub User")
      login_as(@welsh_editor)
    end

    context "when viewing a welsh edition" do
      setup do
        @welsh_edition = FactoryBot.create(:edition, :fact_check, :welsh, requester: @welsh_editor)
        visit edition_path(@welsh_edition)
      end

      should "show the 'Resend fact check' link" do
        assert page.has_link?("Resend fact check email")
        assert page.has_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "show the 'Request amendments' link" do
        assert page.has_link?("Request amendments")
      end

      should "navigate to the 'Request amendments' page when the link is clicked" do
        click_link("Request amendments")
        assert_current_path request_amendments_page_edition_path(@welsh_edition.id)
      end
    end

    context "when viewing a non-welsh edition" do
      setup do
        visit edition_path(@fact_check_edition)
      end

      should "not show the 'Resend fact check' link" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "not show the 'Request amendments' link" do
        assert page.has_no_link?("Request amendments")
      end
    end
  end

  context "user does not have editor permissions" do
    setup do
      login_as(FactoryBot.create(:user, name: "Non Editor"))
      visit edition_path(@fact_check_edition)
    end

    should "not show the 'Resend fact check email' link or text to non-editors" do
      assert page.has_no_link?("Resend fact check email")
      assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
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
  end
end
