require 'integration_test_helper'

class ProgrammeEditionsTest < JavascriptIntegrationTest
  def setup
    setup_users
  end

  test "should have editable part titles" do
    programme = FactoryGirl.create(:programme_edition, :title => "Benefit Example", :slug => "benefit-example")
    programme.save!

    visit "/admin/editions/#{programme.to_param}"

    refute_includes page.body, "Part One"
    refute_includes page.body, "part-one"

    click_on "Overview"
    within :css, "#overview" do
      fill_in "Title", :with => "Imagine this is Welsh"
      fill_in "Body",  :with => "Body text"
      fill_in "Slug",  :with => "imagine-this-is-welsh"
    end

    within(:css, ".workflow_buttons") { click_on "Save" }

    assert_includes page.body, "Programme edition was successfully updated."

    assert_includes page.body, "Imagine this is Welsh"
    refute_includes page.body, "imagine-this-is-welsh"
  end
end
