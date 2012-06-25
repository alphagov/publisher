require 'integration_test_helper'

class AddingPartsToGuidesTest < JavascriptIntegrationTest
  test "Publishing a guide" do
    setup_users

    random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

    guide = GuideEdition.new(:title => random_name, :slug => 'test-guide', :panopticon_id => 2356)
    guide.save!
    guide.update_attribute(:state, 'draft')

    panopticon_has_metadata("id" => '2356')

    visit    "/admin/editions/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', :with => 'Part One'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-one'
    end

    click_on 'Add new part'
    within :css, '#parts div.part:nth-of-type(2)' do
      fill_in 'Title', :with => 'Part Two'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-two'
    end
    within(:css, '.workflow_buttons') { click_on 'Save' }

    click_on 'Add new part'
    within :css, '#parts div.part:nth-of-type(3)' do
      fill_in 'Title', :with => 'Part Three'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-three'
    end
    within(:css, '.workflow_buttons') { click_on 'Save' }

    assert_equal 3, all(:css, '#parts > div.part').length

    visit "/admin?user_filter=all&list=drafts"
    assert page.has_content? random_name
  end

  test "slug for parts should be automatically generated" do
    setup_users

    random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

    guide = GuideEdition.new(:title => random_name, :slug => 'test-guide', :panopticon_id => 2356)
    guide.save!
    guide.update_attribute(:state, 'draft')

    panopticon_has_metadata("id" => '2356')

    visit    "/admin/editions/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', :with => 'Part One'
      fill_in 'Body',  :with => 'Body text'
      assert_equal 'part-one', find(:css, ".slug").value
    end
  end
end
