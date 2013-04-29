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
    guide = FactoryGirl.create(:guide_edition, state: 'published')
    visit_edition guide

    within "div.tabbable" do
      click_on "Admin"
    end

    assert page.has_button?("Create new edition as Quick Answer")

    click_on "Create new edition as Quick Answer"

    assert page.has_content?(guide.title)
    assert page.has_content?("New edition created")
    assert page.has_content?(guide.whole_body)  
  end

  test "should be able to convert an AnswerEdition into a GuideEdition" do
    answer = FactoryGirl.create(:answer_edition, slug: "childcare", title: "meh", body: "bleh", state: 'published')
    visit_edition answer

    within "div.tabbable" do
      click_on "Admin"
    end

    assert page.has_button?("Create new edition as Guide")

    click_on "Create new edition as Guide"

    assert page.has_content?(answer.title)
    assert page.has_content?("New edition created")

    within :css, '#parts div.fields:first-of-type' do
      assert page.has_xpath?("//textarea[text()='#{answer.whole_body}']"), "Expected to see: #{answer.whole_body}"  
    end
  end

  test "should not be able to convert a GuideEdition into an AnswerEdition if not published" do
    guide = FactoryGirl.create(:guide_edition, state: 'ready')
    visit_edition guide

    within "div.tabbable" do
      click_on "Admin"
    end

    refute page.has_button?("Create new edition as Quick Answer")
  end
end
