require 'integration_test_helper'

class AddingPartsToGuidesTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_collections
  end

  test "Publishing a guide" do
    random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

    guide = FactoryGirl.create(:guide_edition, :title => random_name, :slug => 'test-guide')
    guide.save!
    guide.update_attribute(:state, 'draft')

    panopticon_has_metadata("id" => '2356')

    visit    "/editions/#{guide.to_param}"

    add_new_part
    within :css, '#parts div.fields:first-of-type' do
      fill_in 'Title', :with => 'Part One'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-one'
    end

    assert page.has_css?('#parts div.fields', count: 1)

    add_new_part
    within :css, '#parts div.fields:nth-of-type(2)' do
      fill_in 'Title', :with => 'Part Two'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-two'
    end

    assert page.has_css?('#parts div.fields', count: 2)

    add_new_part
    within :css, '#parts div.fields:nth-of-type(3)' do
      fill_in 'Title', :with => 'Part Three'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-three'
    end
    save_edition

    assert page.has_css?('section#parts div#part-one', count: 1)
    assert page.has_css?('section#parts div#part-two', count: 1)
    assert page.has_css?('section#parts div#part-three', count: 1)

    visit "/?user_filter=all&list=drafts"
    assert page.has_content? random_name
  end

  test "slug for new parts should be automatically generated" do
    random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

    guide = FactoryGirl.create(:guide_edition, :title => random_name, :slug => 'test-guide')
    guide.save!
    guide.update_attribute(:state, 'draft')

    panopticon_has_metadata("id" => '2356')

    visit    "/editions/#{guide.to_param}"

    add_new_part
    within :css, '#parts .fields:first-of-type .part' do
      fill_in 'Title', :with => 'Part One'
      fill_in 'Body',  :with => 'Body text'
      assert_equal 'part-one', find(:css, ".slug").value

      fill_in 'Title', :with => 'Part One changed'
      fill_in 'Body',  :with => 'Body text'
      assert_equal 'part-one-changed', find(:css, ".slug").value
    end
  end

  test "slug for edition which has been previously published shouldn't be generated" do
    guide = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'published', :title => "Foo bar")
    guide.save!
    visit_edition guide
    click_on "Create new edition"

    within :css, '#parts .fields:first-of-type .part' do
      assert_equal 'part-one', find(:css, ".slug").value
      fill_in 'Title', :with => 'Part One changed'
      fill_in 'Body',  :with => 'Body text'
      assert_equal 'part-one', find(:css, ".slug").value
    end
  end

end
