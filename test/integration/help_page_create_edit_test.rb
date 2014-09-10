#encoding: utf-8
require 'integration_test_helper'

class HelpPageCreateEditTest < JavascriptIntegrationTest
  setup do
    @artefact = FactoryGirl.create(:artefact,
        slug: "help/hedgehog-topiary",
        kind: "help_page",
        name: "Foo bar",
        owning_app: "publisher",
    )

    setup_users
  end

  should "create a new HelpPageEdition" do
    visit "/publications/#{@artefact.id}"
    
    assert page.has_content? "Viewing “Foo bar” Edition 1"

    h = HelpPageEdition.first
    assert_equal @artefact.id.to_s, h.panopticon_id
  end

  should "allow editing HelpPageEdition" do
    help_page = FactoryGirl.create(:help_page_edition,
                                 :panopticon_id => @artefact.id,
                                 :title => "Foo bar",
                                 :body => "Body content")
    visit "/editions/#{help_page.to_param}"

    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert page.has_field?("Title", :with => "Foo bar")
    assert page.has_field?("Body", :with => "Body content")

    fill_in "Body", :with => "This body has changed"

    save_edition

    assert page.has_content? "Help page edition was successfully updated."

    h = HelpPageEdition.find(help_page.id)
    assert_equal "This body has changed", h.body
  end

  should "allow creating a new version of a HelpPageEdition" do
    help_page = FactoryGirl.create(:help_page_edition,
                                 :panopticon_id => @artefact.id,
                                 :state => 'published',
                                 :title => "Foo bar",
                                 :body => "This is really helpful")
    
    visit "/editions/#{help_page.to_param}"
    
    click_on "Create new edition"

    assert page.has_content? "Viewing “Foo bar” Edition 2"

    assert page.has_field?("Body", :with => "This is really helpful")
  end
end
