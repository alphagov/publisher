require 'integration_test_helper'

class ReportsTest < ActionDispatch::IntegrationTest
  def setup
    alice = FactoryGirl.create(:user, name: "Alice", uid: "alice")
    GDS::SSO.test_user = alice
    @user = alice
    @artefact = FactoryGirl.create(:artefact, name: "Childcare", slug: "childcare")
    @edition = FactoryGirl.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
  end

  def teardown
    GDS::SSO.test_user = nil
  end

  test "can get a CSV of progress" do
    visit "/admin/reports"
    click_link "Export CSV of all non archived editions"
    
    parsed = CSV.parse(page.source, headers: true)
    assert_equal @edition.title, parsed.first['Title']
  end
end