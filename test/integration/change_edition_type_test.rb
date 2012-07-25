require 'integration_test_helper'

class ChangeEditionTypeTest < JavascriptIntegrationTest
  setup do
    panopticon_has_metadata("id" => "2356")
    %w(Alice Bob Charlie).each do |name|
      FactoryGirl.create(:user, name: name)
    end
  end

  teardown do
    GDS::SSO.test_user = nil
  end

  test "should be able to convert a GuideEdition into an AnswerEdition" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356, state: 'published')
    visit_edition guide

    within "div.tabbable" do
      click_on "Admin"
    end

    assert page.has_button? "Convert into an Answer edition"
    click_on "Convert into an Answer edition"

    assert page.has_content? guide.title
    assert page.has_content? guide.whole_body
    assert page.has_content? "Successfully converted Edition type"
  end

  test "should be able to convert an AnswerEdition into a GuideEdition" do
    answer = FactoryGirl.create(:answer_edition, slug: "childcare", title: "meh", body: "bleh", panopticon_id: 2356, state: 'published')
    visit_edition answer

    within "div.tabbable" do
      click_on "Admin"
    end

    assert page.has_button? "Convert into a Guide edition"
    click_on "Convert into a Guide edition"

    assert page.has_content? answer.title
    assert page.has_content? answer.whole_body
    assert page.has_content? "Successfully converted Edition type"
  end
end
