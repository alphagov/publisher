require 'integration_test_helper'

class ProgrammeEditionsTest < JavascriptIntegrationTest
  def setup
    setup_users
    stub_collections
  end

  test "should have editable part titles" do
    programme = FactoryGirl.create(:programme_edition, :title => "Benefit Example", :slug => "benefit-example")
    programme.save!

    visit "/editions/#{programme.to_param}"

    refute_includes page.body, "Part One"
    refute_includes page.body, "part-one"

    click_on "Overview"

    within :css, "#overview" do
      fill_in "Title", :with => "Imagine this is Welsh"
      fill_in "Body",  :with => "Body text"

      # Not clear whether the slug should ever be editable?
      slug_element = page.find('#edition_parts_attributes_0_slug')
      if slug_element && (slug_element['disabled'].nil? || slug_element['disabled'] == 0)
        fill_in "Slug",  :with => "imagine-this-is-welsh"
      end
    end
    save_edition

    assert_includes page.body, "Programme edition was successfully updated."

    assert_includes page.body, "Imagine this is Welsh"
    refute_includes page.body, "imagine-this-is-welsh"
  end
end
