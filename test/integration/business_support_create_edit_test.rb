require "integration_test_helper"

class BusinessSupportCreate < ActionDispatch::IntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
       slug: "hedgehog-topiary",
       kind: "business_support",
       name: "Foo bar",
       owning_app: "publisher",
    )

    setup_users
  end

  def fill_part_body(name, n, content)
    click_on name
    within :css, "#parts div.part:nth-of-type(#{n})" do
      fill_in "Body", :with => content
    end
  end

  should "create a new BusinessSupportEdition" do
    visit "/admin/publications/#{@artefact.id}"

    assert page.has_content? @artefact.name
    assert page.has_content? "Min value"

    fill_in "Short description", :with => "This is the short description"
    fill_in "Min value", :with => 500
    fill_in "Max value", :with => 1000

    parts = [
      ["Description", "Description Body"],
      ["Eligibility", "Eligibility Body"],
      ["Evaluation", "It was really good"],
      ["Additional information", "There is none really"]
    ]
    parts.each_with_index do |part, i|
      fill_part_body part[0], i+1, part[1]
    end


    within :css, ".workflow_buttons" do
      click_on "Save"
    end

    assert page.has_content? @artefact.name


    bs = BusinessSupportEdition.first
    assert_equal @artefact.id.to_s, bs.panopticon_id

    assert_equal "This is the short description", bs.short_description
    assert_equal 500, bs.min_value
    assert_equal 1000, bs.max_value

    assert_equal "Description Body", bs.parts[0].body
    assert_equal "Eligibility Body", bs.parts[1].body
    assert_equal "It was really good", bs.parts[2].body
    assert_equal "There is none really", bs.parts[3].body
  end
end