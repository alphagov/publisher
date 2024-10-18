require "test_helper"

class TabbedNavHelperTest < ActionView::TestCase
  test "#secondary_navigation_tabs_items for draft edition edit page" do
    resource = FactoryBot.create(:guide_edition, title: "Edit page title", state: "draft")

    expected_output = [
      {
        label: "Edit",
        href: "/editions/#{resource.id}",
        current: false,
      },
      {
        label: "Tagging",
        href: "/editions/#{resource.id}/tagging",
        current: false,
      },
      {
        label: "Metadata",
        href: "/editions/#{resource.id}/metadata",
        current: false,
      },
      {
        label: "History and notes",
        href: "/editions/#{resource.id}/history",
        current: false,
      },
      {
        label: "Admin",
        href: "/editions/#{resource.id}/admin",
        current: false,
      },
      {
        label: "Related external links",
        href: "/editions/#{resource.id}/related_external_links",
        current: false,
      },
    ]

    assert_equal expected_output, edition_nav_items(resource)
  end

  test "#secondary_navigation_tabs_items for published edition edit page" do
    resource = FactoryBot.create(:guide_edition, title: "Edit page title", state: "published")

    expected_output = [
      {
        label: "Edit",
        href: "/editions/#{resource.id}",
        current: false,
      },
      {
        label: "Tagging",
        href: "/editions/#{resource.id}/tagging",
        current: false,
      },
      {
        label: "Metadata",
        href: "/editions/#{resource.id}/metadata",
        current: false,
      },
      {
        label: "History and notes",
        href: "/editions/#{resource.id}/history",
        current: false,
      },
      {
        label: "Admin",
        href: "/editions/#{resource.id}/admin",
        current: false,
      },
      {
        label: "Related external links",
        href: "/editions/#{resource.id}/related_external_links",
        current: false,
      },
      {
        label: "Unpublish",
        href: "/editions/#{resource.id}/unpublish",
        current: false,
      },
    ]

    assert_equal expected_output, edition_nav_items(resource)
  end
end
