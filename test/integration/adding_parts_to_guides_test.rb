require 'test_helper'
require 'capybara/rails'

Capybara.default_driver = :selenium


class AddingPartsToGuidesTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  
  def teardown
    DatabaseCleaner.clean
  end
  
  # test "adding parts to a guide doesn't " do
  #   visit    "/"
  #  click_on 'Add new guide'
  #  fill_in  'Title', :with => 'Test guide'
  #   fill_in  'Slug',  :with => 'test-guide'
  #   click_on 'Create Guide'
  #   within :css, '#parts div.part:first-of-type' do
  #     fill_in 'Title' , :with => 'Part One'
  #     fill_in 'Body', :with => 'Body text'
  #     fill_in 'Slug', :with => 'part-one'
  #   end
  #   click_on 'Add new part'
  #   within :css, '#parts div.part:nth-of-type(2)' do
  #     fill_in 'Title' , :with => 'Part Two'
  #     fill_in 'Body', :with => 'Body text'
  #     fill_in 'Slug', :with => 'part-two'
  #   end
  #   within(:css, '#edit') { click_on 'Save' }
  #   click_on 'Add new part'
  #   within :css, '#parts div.part:nth-of-type(3)' do
  #     fill_in 'Title' , :with => 'Part Three'
  #     fill_in 'Body', :with => 'Body text'
  #     fill_in 'Slug', :with => 'part-three'
  #   end
  #   within(:css, '#edit') { click_on 'Save' }
  # 
  #   assert_equal 3, all(:css, '#parts > div.part').length
  # end
end
