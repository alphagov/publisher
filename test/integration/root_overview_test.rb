require 'integration_test_helper'

class RootOverviewTest < ActionDispatch::IntegrationTest
  def filter_by(option)
    visit "/admin"

    select option, from: "Filter by user"
    click_on "Filter"

    click_on "Lined up"
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

    x, y, z = %w[ XXX YYY ZZZ ].map.with_index { |name, i|
      GuideEdition.create(:panopticon_id => i + 1, :title => name, :slug => name.downcase)
    }

    bob.assign(x, alice)
    bob.assign(y, charlie)

    filter_by("All")

    assert page.has_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by("Nobody")

    assert page.has_no_content?("XXX")
    assert page.has_no_content?("YYY")
    assert page.has_content?("ZZZ")

    filter_by("Charlie")

    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")

    visit "/admin"

    # Should remember last selection in session
    assert_equal charlie.uid, page.find_field("Filter by user").value

    click_on "Lined up"
    assert page.has_no_content?("XXX")
    assert page.has_content?("YYY")
    assert page.has_no_content?("ZZZ")
  end
end