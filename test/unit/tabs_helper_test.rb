require 'test_helper'

class TabsHelperTest < ActionView::TestCase
  include TabsHelper

  context 'Tab' do
    should 'return all tabs in order' do
      assert_equal 7, tabs.count
      assert_equal %w(edit tagging metadata history admin related_external_links unpublish), tabs.map(&:name)
    end

    should 'return tabs with expected titles' do
      assert_equal ["Edit", "Tagging", "Metadata", "History and notes", "Admin", "Related external links", "Unpublish"], tabs.map(&:title)
    end

    should 'return tabs with expected paths' do
      assert_equal %w(path path/tagging path/metadata path/history path/admin path/related_external_links path/unpublish), tabs.map { |t| t.path('path') }
    end

    should 'return a single tab by name' do
      assert_equal 'edit', Edition::Tab['edit'].name
    end
  end

  context 'Edit tab' do
    setup do
      @edit_tab = Edition::Tab['edit']
    end

    should 'have a path that matches the one provided' do
      assert_equal 'path/to', @edit_tab.path('path/to')
    end

    should 'have a tab link that targets an element with an ID matching its name' do
      link = tab_link(@edit_tab, 'path/to')
      assert_match 'data-target="#edit"', link
      assert_match 'href="path/to"', link
      assert_match 'aria-controls="edit"', link
      assert_match 'Edit', link
    end
  end
end
