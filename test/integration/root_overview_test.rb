require 'integration_test_helper'

class RootOverviewTest < ActionDispatch::IntegrationTest

  test "filtering by assigned user" do
    without_metadata_denormalisation Guide do

      stub_request(:get, %r{^http://panopticon\.test\.gov\.uk/artefacts/.*\.js$}).
        to_return(status: 200, body: "{}", headers: {})

      # This isn't right, really need a way to run actions when
      # logged in as particular users without having Signonotron running.
      #
      alice   = FactoryGirl.create(:user, name: "Alice")

      bob     = FactoryGirl.create(:user, name: "Bob")
      charlie = FactoryGirl.create(:user, name: "Charlie")

      x, y, z = %w[ XXX YYY ZZZ ].map.with_index { |name, i|
        Guide.create(
          panopticon_id: i + 1,
          name: name,
          slug: name.downcase
        )
      }

      bob.assign(x.editions.first, alice)
      bob.assign(y.editions.first, charlie)

      visit "/admin"

      # Should see only my assigned items by default
      assert page.has_content?("XXX")
      assert page.has_no_content?("YYY")
      assert page.has_no_content?("ZZZ")

      select "All", from: "Filter by user"
      click_on "Filter"

      assert page.has_content?("XXX")
      assert page.has_content?("YYY")
      assert page.has_content?("ZZZ")

      select "Nobody", from: "Filter by user"
      click_on "Filter"

      assert page.has_no_content?("XXX")
      assert page.has_no_content?("YYY")
      assert page.has_content?("ZZZ")

      select "Charlie", from: "Filter by user"
      click_on "Filter"

      assert page.has_no_content?("XXX")
      assert page.has_content?("YYY")
      assert page.has_no_content?("ZZZ")
    end
  end
end
