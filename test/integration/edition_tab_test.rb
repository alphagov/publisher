require 'integration_test_helper'

class EditionTabTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check

    @guide = FactoryBot.create(:guide_edition, state: 'draft')
  end

  def visit_tab(tab)
    if tab == "edit"
      visit_edition @guide
    else
      visit "/editions/#{@guide.to_param}/#{tab}"
    end
  end

  def assert_tab_active(name, title)
    assert page.has_css?('.nav-tabs .active', count: 1), 'More than one tab link active'
    assert page.has_css?('.tab-pane.active', count: 1), 'More than one tab content showing'

    assert page.has_css?('.nav-tabs .active a', text: title), "Tab link not active: #{title}"
    assert page.has_css?("##{name}.tab-pane.active"), "Tab content not active: #{name}"
  end

  with_and_without_javascript do
    should "show the edit tab by default" do
      visit_edition @guide
      assert_tab_active('edit', 'Edit')
    end

    should "show the edit tab after saving whether successful or not" do
      visit_edition @guide
      fill_in 'Title', with: 'New title'
      save_edition_and_assert_success
      assert_tab_active('edit', 'Edit')

      fill_in 'Title', with: ''
      save_edition_and_assert_error
      assert_tab_active('edit', 'Edit')
    end

    should "show the correct tab when visiting tab links" do
      visit_tab('metadata')
      assert_tab_active('metadata', 'Metadata')

      visit_tab('admin')
      assert_tab_active('admin', 'Admin')

      visit_tab('history')
      assert_tab_active('history', 'History and notes')

      visit_tab('tagging')
      assert_tab_active('tagging', 'Tagging')

      visit_tab('related_external_links')
      assert_tab_active('related_external_links', 'Related external links')
    end

    should "show the correct tab when clicking tabs" do
      visit_edition @guide

      click_on('Metadata')
      assert_tab_active('metadata', 'Metadata')

      click_on('Admin')
      assert_tab_active('admin', 'Admin')

      click_on('History and notes')
      assert_tab_active('history', 'History and notes')

      click_on('Edit')
      assert_tab_active('edit', 'Edit')

      click_on('Tagging')
      assert_tab_active('tagging', 'Tagging')

      click_on('Related external links')
      assert_tab_active('related_external_links', 'Related external links')
    end
  end
end
