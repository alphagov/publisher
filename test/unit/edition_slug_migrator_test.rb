require 'test_helper'
require 'edition_slug_migrator'
require 'gds_api/panopticon'

class EditionSlugMigratorTest < ActiveSupport::TestCase
  setup do
    @example_artefact = FactoryGirl.create(:artefact)
    @editions = [
      FactoryGirl.create(:edition, :slug => "first-original-slug", :version_number => 1, :panopticon_id => @example_artefact.id, :state => "published"),
      FactoryGirl.create(:edition, :slug => "first-original-slug", :version_number => 2, :panopticon_id => @example_artefact.id, :state => "draft"),
      FactoryGirl.create(:edition, :slug => "second-original-slug", :state => "published"),
      FactoryGirl.create(:edition, :slug => "third-original-slug", :state => "archived")
    ]

    EditionSlugMigrator.any_instance.stubs(:slugs).returns({
        "first-original-slug" => "first-new-slug",
        "second-original-slug" => "second-new-slug",
        "third-original-slug" => "third-new-slug"
      })
    SearchIndexer.stubs(:call)

    @it = EditionSlugMigrator.new( Logger.new("/dev/null") )
  end

  should "rename the edition slug" do
    @it.run

    @editions.each(&:reload)
    assert_equal ["first-new-slug", "first-new-slug", "second-new-slug", "third-new-slug"], @editions.map(&:slug)
  end

  should "reregister the latest or published edition with Rummager / Publishing API / Router API" do
    ["first-new-slug","second-new-slug","third-new-slug"].each do |slug|
      SearchIndexer.expects(:call).with(responds_with(:slug, slug))
    end

    @it.run
  end

  should "add a note to the edition" do
    @it.run

    @editions.each do |edition|
      edition.reload
      assert edition.actions.select {|a| a.request_type == Action::NOTE }.any?
    end
  end
end
