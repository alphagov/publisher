require 'integration_test_helper'

class AutoSaveEditionTest < JavascriptIntegrationTest
  test "Auto save a guide edition" do
    setup_users

    guide = FactoryGirl.create(:guide_edition, :title => 'How not to lose your work', 
                               :slug => 'test-guide')
    guide.save!
    guide.update_attribute(:state, 'draft')
   
    updated_at = guide.updated_at
    
    assert_equal 0, guide.parts.size

    panopticon_has_metadata("id" => '2356')

    visit "/admin/editions/#{guide.to_param}"

    page.execute_script("GOVUK.autoSave.run();")

    assert_equal '', page.find('.autosave-msg').text

    click_on 'Add new part'
    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', :with => 'Part One'
      fill_in 'Body',  :with => 'Body text'
      fill_in 'Slug',  :with => 'part-one'
    end

    assert page.evaluate_script("GOVUK.autoSave.dirty"), "Expecting the form to be dirty"

    page.execute_script("GOVUK.autoSave.run();")

    assert page.has_selector?('.autosave-msg', :text => /Auto saved at \d\d:\d\d:\d\d/)

    guide.reload

    assert updated_at < guide.updated_at
    assert_equal "Part One", guide.parts.first.title
    assert_equal "Body text", guide.parts.first.body
    assert_equal "part-one", guide.parts.first.slug

    updated_at = guide.updated_at

    assert !page.evaluate_script("GOVUK.autoSave.dirty"), "Expecting the form to be clean" 

    page.execute_script("GOVUK.autoSave.run();")
 
    assert !page.evaluate_script("GOVUK.autoSave.dirty"), "Expecting the form to be clean"
  end

end
