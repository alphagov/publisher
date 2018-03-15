# encoding: UTF-8

require "test_helper"

class TravelAdviceEditionTest < ActiveSupport::TestCase
  should "have correct fields" do
    ed = TravelAdviceEdition.new
    ed.title = "Travel advice for Aruba"
    ed.overview = "This gives travel advice for Aruba"
    ed.country_slug = 'aruba'
    ed.alert_status = %w(avoid_all_but_essential_travel_to_parts avoid_all_travel_to_parts)
    ed.summary = "This is the summary of stuff going on in Aruba"
    ed.version_number = 4
    ed.image_id = "id_from_the_asset_manager_for_an_image"
    ed.document_id = "id_from_the_asset_manager_for_a_document"
    ed.published_at = Time.zone.parse('2013-02-21T14:56:22Z')
    ed.minor_update = true
    ed.change_description = "Some things"
    ed.synonyms = %w(Foo Bar)
    ed.parts.build(title: "Part One", slug: "one")
    ed.save!

    ed = TravelAdviceEdition.first
    assert_equal "Travel advice for Aruba", ed.title
    assert_equal "This gives travel advice for Aruba", ed.overview
    assert_equal 'aruba', ed.country_slug
    assert_equal %w(avoid_all_but_essential_travel_to_parts avoid_all_travel_to_parts), ed.alert_status
    assert_equal "This is the summary of stuff going on in Aruba", ed.summary
    assert_equal 4, ed.version_number
    assert_equal "id_from_the_asset_manager_for_an_image", ed.image_id
    assert_equal "id_from_the_asset_manager_for_a_document", ed.document_id
    assert_equal Time.zone.parse('2013-02-21T14:56:22Z'), ed.published_at
    assert_equal true, ed.minor_update
    assert_equal %w(Foo Bar), ed.synonyms
    assert_equal "Some things", ed.change_description
    assert_equal "Part One", ed.parts.first.title
  end

  context "validations" do
    setup do
      @ta = FactoryBot.build(:travel_advice_edition)
    end

    should "require a country slug" do
      @ta.country_slug = ''
      assert ! @ta.valid?
      assert_includes @ta.errors.messages[:country_slug], "can't be blank"
    end

    should "require a title" do
      @ta.title = ''
      assert ! @ta.valid?
      assert_includes @ta.errors.messages[:title], "can't be blank"
    end

    context "on state" do
      should "only allow one edition in draft per slug" do
        FactoryBot.create(:travel_advice_edition,
                                             country_slug: @ta.country_slug)
        @ta.state = 'draft'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "is already taken"
      end

      should "only allow one edition in published per slug" do
        FactoryBot.create(:published_travel_advice_edition,
                                             country_slug: @ta.country_slug)
        @ta.state = 'published'
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:state], "is already taken"
      end

      should "allow multiple editions in archived per slug" do
        FactoryBot.create(:archived_travel_advice_edition,
                                             country_slug: @ta.country_slug)
        @ta.save!
        @ta.state = 'archived'
        assert @ta.valid?
      end

      should "not conflict with itself when validating uniqueness" do
        @ta.state = 'draft'
        @ta.save!
        assert @ta.valid?
      end
    end

    context "preventing editing of non-draft" do
      should "not allow published editions to be edited" do
        ta = FactoryBot.create(:published_travel_advice_edition)
        ta.title = "Fooey"
        assert ! ta.valid?
        assert_includes ta.errors.messages[:state], "must be draft to modify"
      end

      should "not allow archived editions to be edited" do
        ta = FactoryBot.create(:archived_travel_advice_edition)
        ta.title = "Fooey"
        assert ! ta.valid?
        assert_includes ta.errors.messages[:state], "must be draft to modify"
      end

      should "allow publishing draft editions" do
        ta = FactoryBot.create(:travel_advice_edition)
        assert ta.publish
      end

      should "allow 'save & publish'" do
        ta = FactoryBot.create(:travel_advice_edition)
        ta.title = 'Foo'
        assert ta.publish
      end

      should "allow archiving published editions" do
        ta = FactoryBot.create(:published_travel_advice_edition)
        assert ta.archive
      end

      should "NOT allow 'save & archive'" do
        ta = FactoryBot.create(:published_travel_advice_edition)
        ta.title = 'Foo'
        assert ! ta.archive
        assert_includes ta.errors.messages[:state], "must be draft to modify"
      end
    end

    context "on alert status" do
      should "not permit invalid values in the array" do
        @ta.alert_status = %w(avoid_all_but_essential_travel_to_parts something_else blah)
        assert ! @ta.valid?
        assert_includes @ta.errors.messages[:alert_status], "is not in the list"
      end

      should "permit an empty array" do
        @ta.alert_status = []
        assert @ta.valid?
      end

      # Test that accessing an Array field doesn't mark it as dirty.
      # mongoid/dirty#changes method is patched in lib/mongoid/monkey_patches.rb
      # See https://github.com/mongoid/mongoid/issues/2311 for details.
      should "track changes to alert status accurately" do
        @ta.alert_status = []
        @ta.alert_status
        assert @ta.valid?
      end
    end

    context "on version_number" do
      should "require a version_number" do
        @ta.save # version_number is automatically populated on create, so save it first.
        @ta.version_number = ''
        refute @ta.valid?
        assert_includes @ta.errors.messages[:version_number], "can't be blank"
      end

      should "require a unique version_number per slug" do
        FactoryBot.create(:archived_travel_advice_edition,
                                             country_slug: @ta.country_slug,
                                             version_number: 3)
        @ta.version_number = 3
        refute @ta.valid?
        assert_includes @ta.errors.messages[:version_number], "is already taken"
      end

      should "allow matching version_numbers for different slugs" do
        FactoryBot.create(:archived_travel_advice_edition,
                                             country_slug: 'wibble',
                                             version_number: 3)
        @ta.version_number = 3
        assert @ta.valid?
      end
    end

    context "on minor update" do
      should "not allow first version to be minor update" do
        @ta.minor_update = true
        refute @ta.valid?
        assert_includes @ta.errors.messages[:minor_update], "can't be set for first version"
      end

      should "allow other versions to be minor updates" do
        FactoryBot.create(:published_travel_advice_edition, country_slug: @ta.country_slug)
        @ta.minor_update = true
        assert @ta.valid?
      end
    end

    context "on change_description" do
      should "be required on publish" do
        @ta.save! # Can't save directly as published, have to save as draft first
        @ta.change_description = ""
        @ta.state = "published"
        refute @ta.valid?
        assert_includes @ta.errors.messages[:change_description], "can't be blank on publish"
      end

      should "not be required on publish for a minor update" do
        FactoryBot.create(:archived_travel_advice_edition, country_slug: @ta.country_slug)
        @ta.version_number = 2 # version one can't be minor update
        @ta.save! # Can't save directly as published, have to save as draft first
        @ta.change_description = ""
        @ta.minor_update = true
        @ta.state = "published"
        assert @ta.valid?
      end

      should "not be required when just saving a draft" do
        @ta.change_description = ""
        assert @ta.valid?
      end
    end
  end

  should "have a published scope" do
    FactoryBot.create(:draft_travel_advice_edition)
    e2 = FactoryBot.create(:published_travel_advice_edition)
    FactoryBot.create(:archived_travel_advice_edition)
    e4 = FactoryBot.create(:published_travel_advice_edition)

    assert_equal [e2, e4].sort, TravelAdviceEdition.published.to_a.sort
  end

  context "fields on a new edition" do
    should "be in draft state" do
      assert TravelAdviceEdition.new.draft?
    end

    context "populating version_number" do
      should "set version_number to 1 if there are no existing versions for the country" do
        ed = TravelAdviceEdition.new(country_slug: 'foo')
        ed.valid?
        assert_equal 1, ed.version_number
      end

      should "set version_number to the next available version" do
        FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo', version_number: 1)
        FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo', version_number: 2)
        FactoryBot.create(:published_travel_advice_edition, country_slug: 'foo', version_number: 4)

        ed = TravelAdviceEdition.new(country_slug: 'foo')
        ed.valid?
        assert_equal 5, ed.version_number
      end

      should "do nothing if version_number is already set" do
        ed = TravelAdviceEdition.new(country_slug: 'foo', version_number: 42)
        ed.valid?
        assert_equal 42, ed.version_number
      end

      should "do nothing if country_slug is not set" do
        ed = TravelAdviceEdition.new(country_slug: '')
        ed.valid?
        assert_nil ed.version_number
      end
    end

    should "not be minor_update" do
      assert_equal false, TravelAdviceEdition.new.minor_update
    end
  end

  context "building a new version" do
    setup do
      @ed = FactoryBot.create(:travel_advice_edition,
                               title: "Aruba",
                               overview: "Aruba is not near Wales",
                               country_slug: "aruba",
                               summary: "## The summary",
                               alert_status: %w(avoid_all_but_essential_travel_to_whole_country avoid_all_travel_to_parts),
                               image_id: "id_from_the_asset_manager_for_an_image",
                               document_id: "id_from_the_asset_manager_for_a_document")
      @ed.parts.build(title: "Fooey", slug: 'fooey', body: "It's all about Fooey")
      @ed.parts.build(title: "Gooey", slug: 'gooey', body: "It's all about Gooey")
      @ed.save!
      @ed.publish!
    end

    should "build a new instance with the same fields" do
      new_ed = @ed.build_clone
      assert new_ed.new_record?
      assert new_ed.valid?
      assert_equal @ed.title, new_ed.title
      assert_equal @ed.country_slug, new_ed.country_slug
      assert_equal @ed.overview, new_ed.overview
      assert_equal @ed.summary, new_ed.summary
      assert_equal @ed.image_id, new_ed.image_id
      assert_equal @ed.document_id, new_ed.document_id
      assert_equal @ed.alert_status, new_ed.alert_status
    end

    should "copy the edition's parts" do
      new_ed = @ed.build_clone
      assert_equal %w(Fooey Gooey), new_ed.parts.map(&:title)
    end
  end

  context "previous_version" do
    setup do
      @ed1 = FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo')
      @ed2 = FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo')
      @ed3 = FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo')
    end

    should "return the previous version" do
      assert_equal @ed2, @ed3.previous_version
      assert_equal @ed1, @ed2.previous_version
    end

    should "return nil if there is no previous version" do
      assert_nil @ed1.previous_version
    end
  end

  context "publishing" do
    setup do
      @published = FactoryBot.create(:published_travel_advice_edition, country_slug: 'aruba',
                                      published_at: 3.days.ago, change_description: 'Stuff changed')
      @ed = FactoryBot.create(:travel_advice_edition, country_slug: 'aruba')
      @published.reload
    end

    should "publish the edition and archive related editions" do
      @ed.publish!
      @published.reload
      assert @ed.published?
      assert @published.archived?
    end

    context "setting the published date" do
      should "set the published_at to now for a normal update" do
        Timecop.freeze(1.day.from_now) do
          @ed.publish!
          # The to_i is necessary to account for the difference in milliseconds
          # Time from the db only has a resolution in seconds, whereas Time.zone.now is more accurate
          assert_equal Time.zone.now.utc.to_i, @ed.published_at.to_i
        end
      end

      should "set the published_at to the previous version's published_at for a minor update" do
        @ed.minor_update = true
        @ed.publish!
        assert_equal @published.published_at, @ed.published_at
      end
    end

    should "set the change_description to the previous version's change_description for a minor update" do
      @ed.minor_update = true
      @ed.publish!
      assert_equal @published.change_description, @ed.change_description
    end
  end

  context "setting the reviewed at date" do
    setup do
      @published = FactoryBot.create(:published_travel_advice_edition, country_slug: 'aruba',
                                      published_at: 3.days.ago, change_description: 'Stuff changed')
      @published.reviewed_at = 2.days.ago
      @published.save!
      @published.reload

      Timecop.freeze(1.day.ago) do
        # this is done to make sure there's a significant difference in time
        # between creating the edition and it being published
        @edition = FactoryBot.create(:travel_advice_edition, country_slug: 'aruba')
      end
    end

    should "be updated to published time when edition is published" do
      @edition.change_description = "Did some stuff"
      @edition.publish!
      assert_equal @edition.published_at, @edition.reviewed_at
    end

    should "be set to the previous version's reviewed_at when a minor update is published" do
      @edition.minor_update = true
      @edition.publish!
      assert_equal @published.reviewed_at, @edition.reviewed_at
    end

    should "be able to be updated without affecting other dates" do
      @edition.published_at = Time.zone.now
      @edition.save!
      Timecop.freeze(1.day.from_now) do
        @edition.reviewed_at = Time.zone.now
        assert_equal @edition.published_at, @edition.published_at
      end
    end

    should "be able to update reviewed_at on a published edition" do
      @edition.minor_update = true
      @edition.publish!
      Timecop.freeze(1.day.from_now) do
        new_time = Time.zone.now
        @edition.reviewed_at = new_time
        @edition.save!
        assert_equal new_time.utc.to_i, @edition.reviewed_at.to_i
      end
    end
  end

  context "indexable content" do
    setup do
      @edition = FactoryBot.build(:travel_advice_edition)
    end

    should "return summary and all part titles and bodies" do
      @edition.summary = "The Summary"
      @edition.parts << Part.new(title: "Part One", body: "Some text")
      @edition.parts << Part.new(title: "More info", body: "Some more information")
      assert_equal "The Summary Part One Some text More info Some more information", @edition.indexable_content
    end

    should "convert govspeak to plain text" do
      @edition.summary = "## The Summary"
      @edition.parts << Part.new(title: "Part One", body: "* Some text")
      assert_equal "The Summary Part One Some text", @edition.indexable_content
    end
  end

  context "actions" do
    setup do
      @user = FactoryBot.create(:user)
      @old = FactoryBot.create(:archived_travel_advice_edition, country_slug: 'foo')
      @edition = FactoryBot.create(:draft_travel_advice_edition, country_slug: 'foo')
    end

    should "not have any actions by default" do
      assert_equal 0, @edition.actions.size
    end

    should "add a 'create' action" do
      @edition.build_action_as(@user, Action::CREATE)
      assert_equal 1, @edition.actions.size
      assert_equal Action::CREATE, @edition.actions.first.request_type
      assert_equal @user, @edition.actions.first.requester
    end

    should "add a 'new' action with a comment" do
      @edition.build_action_as(@user, Action::NEW_VERSION, "a comment for the new version")
      assert_equal 1, @edition.actions.size
      assert_equal "a comment for the new version", @edition.actions.first.comment
    end

    context "publish_as" do
      should "add a 'publish' action with change_description as comment on publish" do
        @edition.change_description = "## My hovercraft is full of eels!"
        @edition.publish_as(@user)
        @edition.reload
        assert_equal 1, @edition.actions.size
        action = @edition.actions.last
        assert_equal Action::PUBLISH, action.request_type
        assert_equal @user, action.requester
        assert_equal "My hovercraft is full of eels!", action.comment
      end

      should "add a 'publish' action with 'Minor update' as comment on publish of a minor_update" do
        @edition.minor_update = true
        @edition.publish_as(@user)
        @edition.reload
        assert_equal 1, @edition.actions.size
        action = @edition.actions.last
        assert_equal Action::PUBLISH, action.request_type
        assert_equal "Minor update", action.comment
      end
    end
  end
end
