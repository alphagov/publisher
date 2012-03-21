def check_edition_form_appears_for(edition)
  within('head title') do
    assert page.has_content?("Editing #{edition.title}")
  end

  assert page.has_field? "Assigned to"
  assert page.has_field? "Body"
  assert page.has_button? "Save"
end

def check_form_values_appear_for(edition)
  within("#edit") do
    assert page.has_field? "Alternative title", value_for_field_assertion( edition.alternative_title )
    assert page.has_field? "Meta tag description", value_for_field_assertion( edition.overview )
  end

  within("#metadata") do
    assert page.has_content? format_value( edition.section )
    assert page.has_content? format_value( edition.department )
    assert page.has_content? format_value( edition.slug )
  end
end

def check_editions_appear_in_list(editions, state)
  wait_until { page.has_selector? ".formats tr" }
  editions.each do |edition|
    xpath = '//td[@class="title"][contains(., "' + edition.title + '")]/..'
    row = page.find(:xpath, xpath)
    assert page.has_xpath? xpath

    assert row.has_selector? "img[alt='#{edition.format}edition']"
    assert row.has_content? edition.title
    assert row.has_content? "v.#{edition.version_number}"
    assert row.has_content? (edition.assignee || "")
  end
end

def update_edition_fields(edition)
  fill_in "Alternative title", :with => "A new title"
  fill_in "Meta tag description", :with => "An overview"

  click_button "Save"
end