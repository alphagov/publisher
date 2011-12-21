require 'integration_test_helper'

class ProgressTest < ActionDispatch::IntegrationTest

  test "should be able to see a list of all types of publication in progress" do
    lts = LocalTransactionsSource.create!
    lgsl = lts.lgsls.create!(code: "123")
    lgsl.authorities.create(snac: '00BC')

    Dir.glob(Rails.root.join('app/models/*_edition.rb')).each { |f| require File.basename(f) }
    WholeEdition.subclasses.each do |class_name|
      new_item = class_name.create!(title: "My #{class_name}", slug: class_name.to_s.parameterize, panopticon_id: class_name.to_s, lgsl_code: '123')
      new_item.start_work
    end

    setup_users

    visit "/admin/?filter=all&list=drafts"
    assert page.has_content?("My GuideEdition")
  end

  test "should update progress of a guide" do
    panopticon_has_metadata("id" => '2356')
    setup_users

    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356)
    guide.update_attribute(:state, 'draft')

    visit "/admin/guides/#{guide.to_param}"

    click_on 'Untitled part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end
    click_on "Save"

    click_on "Fact check"

    within "#send_fact_check_form" do
      fill_in "Comment",       with: "Blah"
      fill_in "Email address", with: "user@example.com"
      click_on "Send"
    end

    wait_until { page.has_content? "Status: Fact check" }

    guide.reload

    assert guide.fact_check?
  end
end
