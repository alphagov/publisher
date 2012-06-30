def check_edition_form_appears_for(edition)
  within('head title') do
    assert page.has_content?("Editing #{edition.title}")
  end

  assert page.has_field? "Assigned to"
  assert page.has_field? "Body"
  assert page.has_button? "Save"
end

def check_form_values_appear_for(edition)
  edition.reload

  within("#edit") do
    assert page.has_field? "Alternative title", value_for_field_assertion( edition.alternative_title )
    assert page.has_field? "Meta tag description", value_for_field_assertion( edition.overview )
  end

  within("#metadata") do
    if edition.section.present?
      assert page.has_field? "Section", value_for_field_assertion(edition.section)
    end

    if edition.department.present?
      assert page.has_field? "Department", value_for_field_assertion(edition.department)
    end

    assert page.has_field? "Slug", value_for_field_assertion(edition.slug)
  end
end

def check_editions_appear_in_list(editions, options={})
  # wait_until { page.has_selector? ".formats tr" }
  editions.each do |edition|
    xpath = '//td[@class="title"][contains(., "' + edition.title + '")]/..'
    row = page.find(:xpath, xpath)
    assert page.has_xpath? xpath

    assert row.has_content? edition.title
    assert row.has_content? "Ed. #{edition.version_number}"
    assert row.has_content?((edition.assignee || "")), "Expected to see #{(edition.assignee || "")} in #{row.text}"
    if options.include? :business
      business_cell = row.find('.business')
      assert business_cell.has_content? (options[:business] ? 'Y' : 'N')
    end
  end
end

def update_edition_fields(edition)
  fill_in "Alternative title", :with => "A new title"
  fill_in "Meta tag description", :with => "An overview"

  click_button "Save"
end