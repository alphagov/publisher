require 'test_helper'
require 'edition_slug_migrator'
require 'gds_api/panopticon'

class EditionSlugMigratorTest < ActiveSupport::TestCase

  setup do
    @editions = [
      FactoryGirl.create(:edition, :slug => "first-original-slug"),
      FactoryGirl.create(:edition, :slug => "first-original-slug"),
      FactoryGirl.create(:edition, :slug => "second-original-slug", :state => "published"),
      FactoryGirl.create(:edition, :slug => "third-original-slug", :state => "archived")
    ]

    EditionSlugMigrator.any_instance.stubs(:slugs).returns({
        "first-original-slug" => "first-new-slug",
        "second-original-slug" => "second-new-slug",
        "third-original-slug" => "third-new-slug"
      })
    GdsApi::Panopticon::Registerer.any_instance.stubs(:register)

    @it = EditionSlugMigrator.new( Logger.new("/dev/null") )
  end

  should "rename the edition slug" do
    @it.run

    @editions.each(&:reload)
    assert_equal ["first-new-slug", "first-new-slug", "second-new-slug", "third-new-slug"], @editions.map(&:slug)
  end

  should "reregister the edition with Panopticon" do
    ["first-new-slug","second-new-slug","third-new-slug"].each do |slug|
      GdsApi::Panopticon::Registerer.any_instance.stubs(:register).with(responds_with(:slug, slug)).returns(true)
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
