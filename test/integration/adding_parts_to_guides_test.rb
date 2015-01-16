require 'integration_test_helper'

class AddingPartsToGuidesTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_collections
  end

  context 'creating a guide with parts' do
    setup do
      @random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

      guide = FactoryGirl.create(:guide_edition, :title => @random_name, :slug => 'test-guide')
      guide.save!
      guide.update_attribute(:state, 'draft')

      panopticon_has_metadata("id" => '2356')
      visit_edition guide

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
    end

    should "save the guide and parts using ajax" do
      save_edition_and_assert_success
      assert_correct_parts
      visit current_path
      assert_correct_parts

      visit "/?user_filter=all&list=drafts"
      assert page.has_content? @random_name
    end

    should "be able to hide and show parts" do
      save_edition_and_assert_success

      assert page.has_css?('#part-one input.title')
      click_on 'Part One'
      assert page.has_no_css?('#part-one input.title')
      click_on 'Part One'

      within :css, '#parts div.fields:nth-of-type(1)' do
        fill_in 'Title', :with => 'Part One (edited)'
        fill_in 'Body',  :with => 'Body text'
        fill_in 'Slug',  :with => 'part-one-edited'
      end

      save_edition_and_assert_success

      assert page.has_css?('#part-one-edited input.title')
      click_on 'Part One (edited)'
      assert page.has_no_css?('#part-one-edited input.title')
    end

    should "add the new parts only once" do
      save_edition_and_assert_success
      save_edition_and_assert_success
      save_edition_and_assert_success
      assert_correct_parts

      visit current_path
      assert_correct_parts

      save_edition_and_assert_success
      save_edition_and_assert_success
      assert_correct_parts

      visit current_path
      assert_correct_parts
    end
  end

  test "slug for new parts should be automatically generated" do
    random_name = (0...8).map{65.+(rand(25)).chr}.join + " GUIDE"

    guide = FactoryGirl.create(:guide_edition, :title => random_name, :slug => 'test-guide')
    guide.save!
    guide.update_attribute(:state, 'draft')

    panopticon_has_metadata("id" => '2356')

    visit_edition guide

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

  def assert_correct_parts
    assert page.has_css?('#parts .panel-part', count: 3)
    assert page.has_css?('#parts .panel-title', count: 3)
    assert page.has_css?('#parts .panel-body', count: 3)

    assert page.has_css?('#part-one', count: 1)
    assert_equal page.find('#part-one input.title').value, 'Part One'

    assert page.has_css?('#part-two', count: 1)
    assert_equal page.find('#part-two input.title').value, 'Part Two'

    assert page.has_css?('#part-three', count: 1)
    assert_equal page.find('#part-three input.title').value, 'Part Three'
  end
end
