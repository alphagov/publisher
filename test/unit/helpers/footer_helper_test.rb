require "test_helper"

class FooterHelperTest < ActionView::TestCase
  context "FooterHelper" do
    context "When design system 3b feature toggle is on" do
      setup do
        @test_strategy.switch!(:design_system_edit_phase_3b, true)
      end

      should "show design system footer links when user is an editor" do
        assert_equal [
          { title: "Reports, downtime and users",
            items: [
              { text: "CSV reports", href: reports_path },
              { text: "Downtime messages", href: downtimes_path },
              { text: "Search users", href: user_search_path },
            ] },
          { title: "Support and feedback",
            columns: 2,
            items: [
              { text: "Raise a support request", href: Plek.external_url_for("support") },
              { text: "Check if publishing apps are working or if there’s any maintenance planned", href: "https://status.publishing.service.gov.uk/" },
              { text: "How to write, publish, and improve content", href: "https://www.gov.uk/government/content-publishing" },
            ] },
        ], footer_items(is_editor: true)
      end

      should "not show Downtime and messages link when user is not an editor" do
        assert_equal [
          { title: "Reports, downtime and users",
            items: [
              { text: "CSV reports", href: reports_path },
              { text: "Search users", href: user_search_path },
            ] },
          { title: "Support and feedback",
            columns: 2,
            items: [
              { text: "Raise a support request", href: Plek.external_url_for("support") },
              { text: "Check if publishing apps are working or if there’s any maintenance planned", href: "https://status.publishing.service.gov.uk/" },
              { text: "How to write, publish, and improve content", href: "https://www.gov.uk/government/content-publishing" },
            ] },
        ], footer_items(is_editor: false)
      end
    end
    context "When design system 3b feature toggle is off" do
      setup do
        @test_strategy.switch!(:design_system_edit_phase_3b, false)
      end

      should "show old footer links " do
        assert_equal [
          { title: "Support and feedback",
            items: [
              { text: "Raise a support request", href: Plek.external_url_for("support") },
              { text: "Check if publishing apps are working or if there’s any maintenance planned", href: "https://status.publishing.service.gov.uk/" },
            ] },
        ], footer_items(is_editor: false)
      end
    end
  end
end
