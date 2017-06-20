require "test_helper"

class HelpPageEditionTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryGirl.create(:artefact, kind: 'help_page', slug: "help/foo")
  end

  should "have correct extra fields" do
    h = FactoryGirl.create(
      :help_page_edition,
      panopticon_id: @artefact.id,
      body: "I'm a help page.",
    )

    assert_equal "I'm a help page.", h.body
  end

  should "give a friendly (legacy supporting) description of its format" do
    help_page = HelpPageEdition.new
    assert_equal "HelpPage", help_page.format
  end

  should "return the body as whole_body" do
    h = FactoryGirl.build(
      :help_page_edition,
      panopticon_id: @artefact.id,
      body: "Something",
    )
    assert_equal h.body, h.whole_body
  end

  should "clone extra fields when cloning edition" do
    help_page = FactoryGirl.create(
      :help_page_edition,
      panopticon_id: @artefact.id,
      state: "published",
      body: "I'm very helpful",
    )

    new_help_page = help_page.build_clone
    assert_equal help_page.body, new_help_page.body
  end
end
