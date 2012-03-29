include GdsApi::TestHelpers::Panopticon

# Convert business-ness to a Boolean flag
Transform /^for business $/ do |business|
  true
end

Given /I am signed in to Publisher/ do
  User.create! :name => 'Example User', :email => 'test@gov.uk', :version => 1, :uid => 't3st1ng'
end

Given /(.*?) editions (for business )?exist in Publisher/ do |state, business|
  puts business
  @editions = FactoryGirl.create_list(
    :edition,
    10,
    :state => format_state(state),
    :business_proposition => business || false
  )
end

Given /I have an artefact in Panopticon/ do
  @panopticon_id = 123
  panopticon_has_metadata( "id" => @panopticon_id, "name" => "Test", "slug" => "test", "kind" => "answer", "department" => "GDS", "section" => "Example content" )
end

And /I have clicked the create publication button in Panopticon/ do
  # nothing
end

When /I am redirected to Publisher/ do
  visit admin_publication_path(@panopticon_id)
end

Then /a new edition should be created/ do
  @edition = AnswerEdition.where(:panopticon_id => @panopticon_id).first
  assert @edition.present?
end

When /I visit the editions list/ do
  visit admin_root_path
end

When /filter by everyone/ do
  select "All", :from => 'filter'
  click_button "Filter"
end

When /select the (.*) tab/ do |state|
  # TODO: Actually make the AJAX tab loading work on the list page

  visit admin_root_path(:list => format_state(state) )
end

Then /I should see each (.*) edition in the list/ do |state|
  check_editions_appear_in_list @editions, :state => format_state(state)
end

Then /each edition should be marked as a business edition/ do
  check_editions_appear_in_list @editions, :business => true
end

When /I update fields for an edition/ do
  @edition = @editions.sample
  visit admin_edition_path(@edition)
  update_edition_fields @edition
end

Then /the edition form should show the fields/ do
  check_edition_form_appears_for @edition
  check_form_values_appear_for @edition
end