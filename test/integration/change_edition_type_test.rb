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

    assert_equal true, page.has_button?("Create new edition as Quick Answer")

    click_on "Create new edition as Quick Answer"

    assert_equal true, page.has_content?(guide.title)
    assert_equal true, page.has_content?(guide.whole_body)
    assert_equal true, page.has_content?("New edition created")
  end

  test "should be able to convert an AnswerEdition into a GuideEdition" do
    answer = FactoryGirl.create(:answer_edition, slug: "childcare", title: "meh", body: "bleh", panopticon_id: 2356, state: 'published')
    visit_edition answer

    within "div.tabbable" do
      click_on "Admin"
    end

    assert_equal true, page.has_button?("Create new edition as Guide")

    click_on "Create new edition as Guide"

    assert_equal true, page.has_content?(answer.title)
    assert_equal true, page.has_content?(answer.whole_body)
    assert_equal true, page.has_content?("New edition created")
  end

  test "should not be able to convert a GuideEdition into an AnswerEdition if not published" do
    guide = FactoryGirl.create(:guide_edition, panopticon_id: 2356, state: 'ready')
    visit_edition guide

    within "div.tabbable" do
      click_on "Admin"
    end

    assert_equal false, page.has_button?("Create new edition as Quick Answer")
  end
end
