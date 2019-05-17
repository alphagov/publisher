#encoding: utf-8

require 'integration_test_helper'

class GuideCreateEditTest < JavascriptIntegrationTest
  setup do
    setup_users
    stub_linkables
    stub_holidays_used_by_fact_check

    @artefact = FactoryBot.create(
      :artefact,
      slug: "hedgehog-topiary",
      kind: "guide",
      name: "Foo bar",
      owning_app: "publisher"
    )
  end

  should "create a new GuideEdition" do
    visit "/publications/#{@artefact.id}"

    assert page.has_content?(/Foo bar\W#1/)

    g = GuideEdition.first
    assert_equal @artefact.id.to_s, g.panopticon_id
    assert_equal "Foo bar", g.title
  end

  should "editing a GuideEdition, and hiding chapter navigation" do
    guide = FactoryBot.create(:guide_edition,
                              panopticon_id: @artefact.id,
                              state: 'draft',
                              title: "Foo bar #0")

    visit_edition guide
    assert_not find('#edition_hide_chapter_navigation').checked?

    # using 'check' and similar capybara approaches does not work here for some reason
    page.execute_script("$('#edition_hide_chapter_navigation').attr('checked', 'checked')")

    assert find('#edition_hide_chapter_navigation').checked?
    save_edition_and_assert_success

    visit_edition guide
    assert find('#edition_hide_chapter_navigation').checked?
  end

  should "show hide_chapter_navigation as selected" do
    guide = FactoryBot.build(:guide_edition,
                             panopticon_id: @artefact.id,
                             state: 'draft',
                             title: "Foo bar #0")
    guide.hide_chapter_navigation = true
    guide.save!

    visit_edition guide
    assert find('#edition_hide_chapter_navigation').checked?
  end

  should "editing a GuideEdition, and adding some parts" do
    guide = FactoryBot.build(:guide_edition,
                             panopticon_id: @artefact.id,
                             title: "Foo bar")
    guide.parts.build(title: "Placeholder", body: "placeholder", slug: 'placeholder', order: 1)
    guide.save!

    visit_edition guide

    assert page.has_content?(/Foo bar\W#1/)

    within :css, '#parts div.part:first-of-type' do
      fill_in 'Title', with: 'Part One'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-one'
    end

    click_on 'Add new part'
    assert page.has_css?('#parts div.fields', count: 2)
    within :css, '#parts div.fields:nth-of-type(2)' do
      fill_in 'Title', with: 'Part Two'
      fill_in 'Body',  with: 'Body text'
      fill_in 'Slug',  with: 'part-two'
    end

    save_edition_and_assert_success

    g = GuideEdition.find(guide.id)
    assert_equal ['Part One', 'Part Two'], g.parts.map(&:title)
    assert_equal [1, 2], g.parts.map(&:order)
  end

  should "allow creating a new version of a GuideEdition" do
    guide = FactoryBot.create(:guide_edition_with_two_parts,
                              panopticon_id: @artefact.id,
                              state: 'published',
                              title: "Foo bar")
    guide.save!

    visit_edition guide
    click_on "Create new edition"

    assert page.has_content?(/Foo bar\W#2/)

    g2 = GuideEdition.where(version_number: 2).first

    assert_equal guide.parts.map(&:title), g2.parts.map(&:title)
  end

  should "disable fields for a published edition" do
    edition = FactoryBot.create(:guide_edition_with_two_parts,
                                panopticon_id: @artefact.id,
                                state: 'published',
                                title: "Foo bar")

    visit_edition edition
    assert_all_edition_fields_disabled(page)
  end
end
