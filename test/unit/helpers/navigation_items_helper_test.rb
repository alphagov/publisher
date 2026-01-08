require "test_helper"

class NavigationItemsHelperTest < ActionView::TestCase
  context "NavigationItemsHelper" do
    context "When design system 3b feature toggle is off" do
      setup do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:design_system_edit_phase_3b, false)
      end

      should "include editor-only links when user is an editor" do
        assert_equal [
          { text: "Publications", href: root_path, active: false },
          { text: "Add artefact", href: new_artefact_path, active: false },
          { text: "Downtime", href: downtimes_path, active: false },
          { text: "Reports", href: reports_path, active: false },
          { text: "Search by user", href: user_search_path, active: false },
          { text: "Sign out", href: "/auth/gds/sign_out" },
        ], navigation_items(is_editor: true)
      end

      should "not include editor-only links when user is not an editor" do
        assert_equal [
          { text: "Publications", href: root_path, active: false },
          { text: "Reports", href: reports_path, active: false },
          { text: "Search by user", href: user_search_path, active: false },
          { text: "Sign out", href: "/auth/gds/sign_out" },
        ], navigation_items(is_editor: false)
      end

      should "include user name link if user has name" do
        assert_includes navigation_items(is_editor: false, user_name: "Name"), { text: "Name", href: Plek.new.external_url_for("signon") }
      end

      should "apply set link to active if page is current link" do
        paths = [
          root_path,
          new_artefact_path,
          downtimes_path,
          reports_path,
          user_search_path,
        ]

        paths.each do |path|
          returned_items = navigation_items(is_editor: true, path:)
          path_item = returned_items.find { |item| item[:href] == path }
          other_items = returned_items.filter { |item| item[:href] != path && item[:href] != "auth/gds/sign_out" }
          sign_out_item = returned_items.find { |item| item[:href] == "/auth/gds/sign_out" }

          assert path_item[:active]

          other_items.each do |item|
            assert_not item[:active]
          end

          assert_nil sign_out_item[:active]
        end
      end
    end

    context "When design system 3b feature toggle is on" do
      setup do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:design_system_edit_phase_3b, true)
      end
      should "include editor-only links when user is an editor" do
        assert_equal [
          { text: "My content", href: my_content_path, active: false },
          { text: "Find content", href: find_content_path, active: false },
          { text: "2i queue", href: two_eye_queue_path, active: false },
          { text: "Add artefact", href: new_artefact_path, active: false },
          { text: "Sign out", href: "/auth/gds/sign_out" },
        ], navigation_items(is_editor: true)
      end

      should "not include editor-only links when user is not an editor" do
        assert_equal [
          { text: "My content", href: my_content_path, active: false },
          { text: "Find content", href: find_content_path, active: false },
          { text: "2i queue", href: two_eye_queue_path, active: false },
          { text: "Sign out", href: "/auth/gds/sign_out" },
        ], navigation_items(is_editor: false)
      end

      should "include user name link if user has name" do
        assert_equal [
          { text: "My content", href: my_content_path, active: false },
          { text: "Find content", href: find_content_path, active: false },
          { text: "2i queue", href: two_eye_queue_path, active: false },
          { text: "Name", href: Plek.new.external_url_for("signon") },
          { text: "Sign out", href: "/auth/gds/sign_out" },
        ], navigation_items(is_editor: false, user_name: "Name")
      end

      should "apply set link to active if page is current link" do
        paths = [
          my_content_path,
          two_eye_queue_path,
          new_artefact_path,
        ]

        paths.each do |path|
          returned_items = navigation_items(is_editor: true, path:)
          path_item = returned_items.find { |item| item[:href] == path }
          other_items = returned_items.filter { |item| item[:href] != path && item[:href] != "auth/gds/sign_out" }
          sign_out_item = returned_items.find { |item| item[:href] == "/auth/gds/sign_out" }

          assert path_item[:active]

          other_items.each do |item|
            assert_not item[:active]
          end

          assert_nil sign_out_item[:active]
        end
      end
    end
  end
end
