require 'integration_test_helper'

class MarkEditionInBetaTest < JavascriptIntegrationTest
  setup do
    setup_users
  end

  should "allow marking an edition as in beta" do
    edition = FactoryGirl.create(:edition)

    visit "/editions/#{edition.to_param}"
    refute find('#edition_in_beta').checked?

    check 'Content is in beta'
    save_edition

    assert find('#edition_in_beta').checked?

    visit "/?user_filter=all"
    assert page.has_text?("#{edition.title} (Ed. 1) beta")
  end

  should "allow marking an edition as not in beta" do
    edition = FactoryGirl.create(:edition, in_beta: true)

    visit "/editions/#{edition.to_param}"
    assert find('#edition_in_beta').checked?

    uncheck 'Content is in beta'
    save_edition

    refute find('#edition_in_beta').checked?

    visit "/?user_filter=all"
    refute page.has_text?("#{edition.title} (Ed. 1) beta")
  end

end
