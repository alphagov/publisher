require "test_helper"

class ArtefactTest < ActiveSupport::TestCase
  context "validating slug" do
    should "allow nice clean slugs" do
      a = FactoryGirl.build(:artefact, slug: "its-a-nice-day")
      assert a.valid?
    end

    should "not allow apostrophes in slugs" do
      a = FactoryGirl.build(:artefact, slug: "it's-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow spaces in slugs" do
      a = FactoryGirl.build(:artefact, slug: "it is-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow slashes in slugs when the namespace is not 'done' or 'help'" do
      a = FactoryGirl.build(:artefact, slug: "something-else/its-a-nice-day")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "allow travel-advice to have a slug prefixed with 'foreign-travel-advice/'" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba", kind: "travel-advice")
      assert a.valid?
    end

    should "allow help pages to have a slug prefixed with 'help/'" do
      a = FactoryGirl.build(:artefact, slug: "help/a-page", kind: "help_page")
      assert a.valid?
    end

    should "allow done pages to have a slug prefixed with 'done/'" do
      a = FactoryGirl.build(:artefact, slug: "done/a-page", kind: "completed_transaction")
      assert a.valid?
    end

    should "not allow multiple slashes in travel-advice artefacts" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba/foo", kind: "travel-advice")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow a foreign-travel-advice prefix for non-travel-advice artefacts" do
      a = FactoryGirl.build(:artefact, slug: "foreign-travel-advice/aruba", kind: "answer")
      refute a.valid?
      assert a.errors[:slug].any?
    end

    context "help page special case" do
      should "allow a help page to have a help/ prefix on the slug" do
        a = FactoryGirl.build(:artefact, slug: "help/foo", kind: "help_page")
        assert a.valid?
      end

      should "require a help page to have a help/ prefix on the slug" do
        a = FactoryGirl.build(:artefact, slug: "foo", kind: "help_page")
        refute a.valid?
        assert_equal 1, a.errors[:slug].count
      end

      should "not allow other kinds to have a help/ prefix" do
        a = FactoryGirl.build(:artefact, slug: "help/foo", kind: "answer")
        refute a.valid?
        assert_equal 1, a.errors[:slug].count
      end
    end
  end

  context "#need_ids" do
    should "be empty by default" do
      assert_empty FactoryGirl.build(:artefact).need_ids
    end

    should "do validations if nil" do
      artefact = FactoryGirl.create(:artefact, need_ids: ["100001"])
      artefact.need_ids = nil

      assert_nothing_raised { artefact.valid? }
    end

    should "filter out empty strings" do
      artefact = FactoryGirl.create(:artefact, need_ids: ["", "100002"])
      assert_equal ["100002"], artefact.reload.need_ids
    end

    should "store multiple needs related to an artefact" do
      artefact = FactoryGirl.create(:artefact, need_ids: %w(100001 100002))
      assert_equal %w(100001 100002), artefact.reload.need_ids
    end

    should "be six-digit integers" do
      artefact = FactoryGirl.build(:artefact, need_ids: ["B1231"])

      refute artefact.valid?
      assert_includes artefact.errors[:need_ids], "must be six-digit integer strings"
    end

    should "not validate need ids that were migrated from the singular need_id field" do
      artefact = FactoryGirl.create(:artefact)
      # simulate what happened during migration
      artefact.set(need_ids: ['As an employer
                                I need to know which type of DBS check an employee needs
                                so that I can apply for the correct one'])

      artefact.need_ids << "100045"

      assert artefact.valid?
    end

    context "for backwards compatibility" do
      setup do
        @artefact = FactoryGirl.create(:artefact)
      end

      should "append to need_ids when need_id is assigned" do
        @artefact.need_id = "100045"

        assert_equal "100045", @artefact.need_id
        assert_includes @artefact.need_ids, "100045"
      end

      should "append to existing need_ids when need_id is assigned" do
        @artefact.set(need_ids: ["100044"])
        @artefact.set(need_id: "100044")

        @artefact.need_id = "100045"

        assert_equal "100045", @artefact.need_id
        assert_equal %w(100044 100045), @artefact.need_ids
      end

      # this should only matter till the time we have both fields
      # need_id and need_ids. can delete this test once we unset need_id.
      should "keep need_ids unchanged when need_id is removed" do
        @artefact.set(need_ids: %w(100044 100045))
        @artefact.set(need_id: "100044")

        @artefact.need_id = nil

        assert_nil @artefact.need_id
        assert_equal %w(100044 100045), @artefact.need_ids
      end
    end
  end

  context "validating paths and prefixes" do
    setup do
      @a = FactoryGirl.build(:artefact)
    end

    should "be valid when empty" do
      @a.paths = []
      @a.prefixes = []
      assert @a.valid?

      @a.paths = nil
      @a.prefixes = nil
      assert @a.valid?
    end

    should "be valid when set to array of absolute URL paths" do
      @a.paths = ["/foo.json"]
      @a.prefixes = ["/foo", "/bar"]
      assert @a.valid?
    end

    should "be invalid if an entry is not a valid absolute URL path" do
      [
        "not a URL path",
        "http://foo.example.com/bar",
        "bar/baz",
        "/foo/bar?baz=qux",
      ].each do |path|
        @a.paths = ["/foo.json", path]
        @a.prefixes = ["/foo", path]
        refute @a.valid?
        assert_equal 1, @a.errors[:paths].count
        assert_equal 1, @a.errors[:prefixes].count
      end
    end

    should "be invalid with consecutive or trailing slashes" do
      [
        "/foo//bar",
        "/foo/bar///",
        "//bar/baz",
        "//",
        "/foo/bar/",
      ].each do |path|
        @a.paths = ["/foo.json", path]
        @a.prefixes = ["/foo", path]
        refute @a.valid?
        assert_equal 1, @a.errors[:paths].count
        assert_equal 1, @a.errors[:prefixes].count
      end
    end

    should "skip validating these if they haven't changed" do
      # This validation can be expensive, so skip it where unnecessary.
      @a.paths = ["foo"]
      @a.prefixes = ["bar"]
      @a.save validate: false

      assert @a.valid?
    end
  end

  test "should translate kind into internally normalised form" do
    a = Artefact.new(kind: "benefit / scheme")
    a.normalise
    assert_equal "programme", a.kind
  end

  test "should not translate unknown kinds" do
    a = Artefact.new(kind: "other")
    a.normalise
    assert_equal "other", a.kind
  end

  test "should raise a not found exception if the slug doesn't match" do
    assert_raise Mongoid::Errors::DocumentNotFound do
      Artefact.from_param("something-fake")
    end
  end

  should "update the edition's slug when a draft artefact is saved" do
    artefact = FactoryGirl.create(:draft_artefact)
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)

    artefact.slug = "something-something-draft"
    artefact.save!

    edition.reload
    assert_equal artefact.slug, edition.slug
  end

  should "not touch the updated_at field on the editions when the artefact is saved but the slug hasn't changed" do
    artefact = FactoryGirl.create(:draft_artefact)
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id)
    two_days_ago = Time.zone.today - 2
    old_updated_at = Time.zone.local(two_days_ago.year, two_days_ago.month, two_days_ago.day).time
    edition.set(updated_at: old_updated_at)

    artefact.language = "cy"
    artefact.save!

    edition.reload
    assert_equal old_updated_at.utc.iso8601, edition.updated_at.utc.iso8601
  end

  should "not update the edition's slug when a live artefact is saved" do
    artefact = FactoryGirl.create(:live_artefact, slug: "something-something-live")
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  should "not update the edition's slug when an archived artefact is saved" do
    artefact = FactoryGirl.create(:live_artefact, slug: "something-something-live")
    edition = FactoryGirl.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.state = 'archived'
    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  test "should not let you edit the slug if the artefact is live" do
    artefact = FactoryGirl.create(:artefact,
        slug: "too-late-to-edit",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",
        state: "live")

    artefact.slug = "belated-correction"
    refute artefact.save

    assert_equal "too-late-to-edit", artefact.reload.slug
  end

  # should continue to work in the way it has been:
  # i.e. you can edit everything but the name/title for published content in panop
  test "on save title should not be applied to already published content" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",)

    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)
    edition.state = "published"
    edition.save!

    assert_equal artefact.name, edition.title

    artefact.name = "Babar"
    artefact.save

    edition.reload
    assert_not_equal artefact.name, edition.title
  end

  test "should indicate when any editions have been published for this artefact" do
    artefact = FactoryGirl.create(:artefact,
        slug: "foo-bar",
        kind: "answer",
        name: "Foo bar",
        owning_app: "publisher",)
    user1 = FactoryGirl.create(:user)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)

    refute artefact.any_editions_published?

    edition.state = "published"
    edition.save!

    assert artefact.any_editions_published?
  end

  test "should have 'video' as a supported FORMAT" do
    assert_includes Artefact::FORMATS, "video"
  end

  test "should find the default owning_app for a format" do
    assert_equal "publisher", Artefact.default_app_for_format("guide")
  end

  test "should allow creation of artefacts with 'video' as the kind" do
    artefact = Artefact.create!(slug: "omlette-du-fromage", name: "Omlette du fromage", kind: "video", owning_app: "Dexter's Lab")

    refute artefact.nil?
    assert_equal "video", artefact.kind
  end

  test "should archive all editions when archived" do
    artefact = FactoryGirl.create(:artefact, state: "live")
    editions = %w(draft ready published archived).map { |state|
      FactoryGirl.create(:programme_edition, panopticon_id: artefact.id, state: state)
    }
    user1 = FactoryGirl.create(:user)

    artefact.update_attributes_as(user1, state: "archived")
    artefact.save!

    editions.each(&:reload)
    editions.each do |edition|
      assert_equal "archived", edition.state
    end
    # remove the previously already archived edition, as no note will have been added
    editions.pop
    editions.each do |edition|
      assert_equal "Artefact has been archived. Archiving this edition.", edition.actions.first.comment
    end
  end

  test "should not run validations on editions when archiving" do
    artefact = FactoryGirl.create(:artefact, state: "live")
    edition = FactoryGirl.create(:help_page_edition, panopticon_id: artefact.id, state: 'published')
    user1 = FactoryGirl.create(:user)

    # Make the edition invalid, check that it persisted the invalid state
    edition.update_attribute(:title, nil)
    assert_nil edition.reload.title

    artefact.update_attributes_as(user1, state: "archived")
    artefact.save!

    assert_equal("archived", edition.reload.state)
  end

  test "should restrict what attributes can be updated on an edition that has an archived artefact" do
    artefact = FactoryGirl.create(:artefact, state: "live")
    edition = FactoryGirl.create(:programme_edition, panopticon_id: artefact.id, state: "published")
    artefact.state = "archived"
    artefact.save
    assert_raise RuntimeError do
      edition.update_attributes(state: "archived", title: "Shabba", slug: "do-not-allow")
    end
  end

  context "artefact language" do
    should "return english by default" do
      a = FactoryGirl.create(:artefact)

      assert_equal 'en', a.language
    end

    should "accept welsh language" do
      a = FactoryGirl.build(:artefact)
      a.language = 'cy'
      a.save

      a = Artefact.first
      assert_equal 'cy', a.language
    end

    should "reject a language which is not english or welsh" do
      a = FactoryGirl.build(:artefact)
      a.language = 'pirate'

      assert ! a.valid?
    end
  end

  should "have an archived? helper method" do
    published_artefact = FactoryGirl.create(:artefact, slug: "scooby", state: "live")
    archived_artefact = FactoryGirl.create(:artefact, slug: "doo", state: "archived")

    refute published_artefact.archived?
    assert archived_artefact.archived?
  end

  context "#exact_route?" do
    context 'for artefacts without a latest edition' do
      should 'be true if its owning_app is not publisher and it has no prefixes' do
        assert FactoryGirl.build(:artefact, :non_publisher, prefixes: []).exact_route?
      end

      should 'be false if its owning_app is not publisher and it has prefixes' do
        refute FactoryGirl.build(:artefact, :non_publisher, prefixes: ['/hats']).exact_route?
      end

      should 'be true if its owning_app is publisher and its kind is that of an exact route edition' do
        assert FactoryGirl.build(:artefact, kind: 'campaign', prefixes: []).exact_route?
        assert FactoryGirl.build(:artefact, kind: 'help_page', prefixes: []).exact_route?
        assert FactoryGirl.build(:artefact, kind: 'transaction', prefixes: []).exact_route?

        # regardless of prefixes
        assert FactoryGirl.build(:artefact, kind: 'campaign', prefixes: ['/hats']).exact_route?
        assert FactoryGirl.build(:artefact, kind: 'help_page', prefixes: ['/shoes']).exact_route?
        assert FactoryGirl.build(:artefact, kind: 'transaction', prefixes: ['/scarves']).exact_route?
      end

      should 'be false if its owning_app is not publisher and its kind is not that of an exact route edition' do
        refute FactoryGirl.build(:artefact, kind: 'answer', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'completed_transaction', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'guide', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'licence', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'local_transaction', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'place', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'programme', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'simple_smart_answer', prefixes: []).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'video', prefixes: []).exact_route?

        # regardless of prefixes
        refute FactoryGirl.build(:artefact, kind: 'answer', prefixes: ['/hats']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'completed_transaction', prefixes: ['/scarves']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'guide', prefixes: ['/underwear']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'licence', prefixes: ['/jumpers']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'local_transaction', prefixes: ['/gloves']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'place', prefixes: ['/belts']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'programme', prefixes: ['/socks']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'simple_smart_answer', prefixes: ['/onesies']).exact_route?
        refute FactoryGirl.build(:artefact, kind: 'video', prefixes: ['/all-other-clothing']).exact_route?
      end
    end

    context 'for artefacts with a latest edition' do
      should 'delegate to it' do
        latest_edition = mock
        artefact = FactoryGirl.build(:artefact)
        artefact.stubs(:latest_edition).returns(latest_edition)

        latest_edition.expects(:exact_route?).returns true
        assert artefact.exact_route?

        latest_edition.expects(:exact_route?).returns false
        refute artefact.exact_route?
      end
    end
  end
end
