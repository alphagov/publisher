include GdsApi::TestHelpers::Panopticon

Given /I am signed in to Publisher/ do
  User.create! :name => 'Example User', :email => 'test@gov.uk', :version => 1, :uid => 't3st1ng'
end

Given /editions exist in Publisher/ do
  FactoryGirl.create_list(:guide_edition, 10)
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

Then /I should see the edit edition form/ do
  within('head title') do
    assert page.has_content?("Editing #{@edition.title}")
  end

  assert page.has_field? "Assigned to"
  assert page.has_field? "Body"
  assert page.has_button? "Save"
end

Then /the artefact metadata should be present/ do
  within("#metadata") do
    assert page.has_content? @edition.section
    assert page.has_content? @edition.department
    assert page.has_content? @edition.slug
  end
end