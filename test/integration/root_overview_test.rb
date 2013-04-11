require_relative '../integration_test_helper'

class RootOverviewTest < ActionDispatch::IntegrationTest
  def filter_by_user(option)
    within ".user-filter-form" do
      select option, from: "Filter by assignee"
      click_on "Filter"
    end
    click_on "Lined up"
  end

  def filter_by_content(substring)
    within ".string-filter-form" do
      fill_in "Filter", with: substring
      click_on "Filter"
    end
  end

  test "filtering by assigned user" do
    stub_request(:get, %r{^http://panopticon\.test\.gov\.uk/artefacts/.*\.js$}).
      to_return(status: 200, body: "{}", headers: {})

    # This isn't right, really need a way to run actions when
    # logged in as particular users without having Signonotron running.
    #
    alice   = FactoryGirl.create(:user, name: "Alice", uid: "alice")

    bob     = FactoryGirl.create(:user, name: "Bob", uid: "bob")
    charlie = FactoryGirl.create(:user, name: "Charlie", uid: "charlie")

    x =  FactoryGirl.create(:guide_edition, :title => "XXX", :slug => "xxx")
    y =  FactoryGirl.create(:guide_edition, :title => "YYY", :slug => "yyy")
    z =  FactoryGirl.create(:guide_edition, :title => "ZZZ", :slug => "zzz")

    bob.assign(x, alice)
    bob.assign(y, charlie)

    visit "/admin"

    filter_by_user("All")

    assert page.has_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by_user("Nobody")

    assert page.has_no_content?("XXX")
    assert page.has_no_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by_user("Charlie")

    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")

    visit "/admin"

    # Should remember last selection in session
    assert_equal charlie.uid, page.find_field("Filter by assignee").value

    click_on "Lined up"
    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")
  end

  test "filtering by title content" do
    stub_request(:get, %r{^http://panopticon\.test\.gov\.uk/artefacts/.*\.js$}).
      to_return(status: 200, body: "{}", headers: {})

    FactoryGirl.create(:user)
    FactoryGirl.create(:guide_edition, :title => "XXX")
    FactoryGirl.create(:guide_edition, :title => "YYY")

    visit "/admin"
    filter_by_user("All")

    filter_by_content("xXx")

    assert page.has_content?("XXX")
    assert page.has_no_content?("YYY")
  end

  test "filtering by title content should not lose the active section" do
    stub_request(:get, %r{^http://panopticon\.test\.gov\.uk/artefacts/.*\.js$}).
      to_return(status: 200, body: "{}", headers: {})

    FactoryGirl.create(:user)

    visit "/admin"
    click_on "Amends needed"
    
    filter_by_content("xXx")

    assert page.has_css?('h1', text: "Amends needed")
  end
end
