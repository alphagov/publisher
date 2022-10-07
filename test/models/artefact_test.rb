require "test_helper"

class ArtefactTest < ActiveSupport::TestCase
  context "validating slug" do
    should "allow nice clean slugs" do
      a = FactoryBot.build(:artefact, slug: "its-a-nice-day")
      assert a.valid?
    end

    should "not allow apostrophes in slugs" do
      a = FactoryBot.build(:artefact, slug: "it's-a-nice-day")
      assert_not a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow spaces in slugs" do
      a = FactoryBot.build(:artefact, slug: "it is-a-nice-day")
      assert_not a.valid?
      assert a.errors[:slug].any?
    end

    should "not allow slashes in slugs when the namespace is not 'done' or 'help'" do
      a = FactoryBot.build(:artefact, slug: "something-else/its-a-nice-day")
      assert_not a.valid?
      assert a.errors[:slug].any?
    end

    should "allow help pages to have a slug prefixed with 'help/'" do
      a = FactoryBot.build(:artefact, slug: "help/a-page", kind: "help_page")
      assert a.valid?
    end

    should "allow done pages to have a slug prefixed with 'done/'" do
      a = FactoryBot.build(:artefact, slug: "done/a-page", kind: "completed_transaction")
      assert a.valid?
    end

    context "help page special case" do
      should "allow a help page to have a help/ prefix on the slug" do
        a = FactoryBot.build(:artefact, slug: "help/foo", kind: "help_page")
        assert a.valid?
      end

      should "require a help page to have a help/ prefix on the slug" do
        a = FactoryBot.build(:artefact, slug: "foo", kind: "help_page")
        assert_not a.valid?
        assert_equal 1, a.errors[:slug].count
      end

      should "not allow other kinds to have a help/ prefix" do
        a = FactoryBot.build(:artefact, slug: "help/foo", kind: "answer")
        assert_not a.valid?
        assert_equal 1, a.errors[:slug].count
      end
    end

    should "trim whitespace from URLs" do
      artefact = FactoryBot.build(:artefact, redirect_url: " https://www.gov.uk ")
      assert artefact.valid?
      assert artefact.redirect_url == "https://www.gov.uk"
    end
  end

  context "validating paths and prefixes" do
    setup do
      @a = FactoryBot.build(:artefact)
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
        assert_not @a.valid?
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
        assert_not @a.valid?
        assert_equal 1, @a.errors[:paths].count
        assert_equal 1, @a.errors[:prefixes].count
      end
    end

    should "skip validating these if they haven't changed" do
      # This validation can be expensive, so skip it where unnecessary.
      @a.paths = %w[foo]
      @a.prefixes = %w[bar]
      @a.save! validate: false

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
    artefact = FactoryBot.create(:draft_artefact)
    edition = FactoryBot.create(:answer_edition, panopticon_id: artefact.id)

    artefact.slug = "something-something-draft"
    artefact.save!

    edition.reload
    assert_equal artefact.slug, edition.slug
  end

  should "not touch the updated_at field on the editions when the artefact is saved but the slug hasn't changed" do
    artefact = FactoryBot.create(:draft_artefact)
    edition = FactoryBot.create(:answer_edition, panopticon_id: artefact.id)
    two_days_ago = Time.zone.today - 2
    old_updated_at = Time.zone.local(two_days_ago.year, two_days_ago.month, two_days_ago.day).time
    edition.set(updated_at: old_updated_at)

    artefact.language = "cy"
    artefact.save!

    edition.reload
    assert_equal old_updated_at.utc.iso8601, edition.updated_at.utc.iso8601
  end

  should "not update the edition's slug when a live artefact is saved" do
    artefact = FactoryBot.create(:live_artefact, slug: "something-something-live")
    edition = FactoryBot.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  should "not update the edition's slug when an archived artefact is saved" do
    artefact = FactoryBot.create(:live_artefact, slug: "something-something-live")
    edition = FactoryBot.create(:answer_edition, panopticon_id: artefact.id, slug: "something-else")

    artefact.state = "archived"
    artefact.save!

    edition.reload
    assert_equal "something-else", edition.slug
  end

  # should continue to work in the way it has been:
  # i.e. you can edit everything but the name/title for published content in panop
  test "on save title should not be applied to already published content" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )

    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)
    edition.state = "published"
    edition.save!

    assert_equal artefact.name, edition.title

    artefact.name = "Babar"
    artefact.save!

    edition.reload
    assert_not_equal artefact.name, edition.title
  end

  test "should not change the slug of published editions when the artefact slug is changed" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "too-late-to-edit",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
      state: "live",
    )

    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)
    edition.state = "published"
    edition.save!

    artefact.slug = "belated-correction"
    artefact.save!

    assert_equal "too-late-to-edit", edition.reload.slug
  end

  test "should change the slug of draft editions when the artefact slug is changed" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "too-late-to-edit",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
      state: "live",
    )

    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)
    edition.state = "draft"
    edition.save!

    artefact.slug = "belated-correction"
    artefact.save!

    assert_equal "belated-correction", edition.reload.slug
  end

  test "should indicate when any editions have been published for this artefact" do
    artefact = FactoryBot.create(
      :artefact,
      slug: "foo-bar",
      kind: "answer",
      name: "Foo bar",
      owning_app: "publisher",
    )
    user1 = FactoryBot.create(:user, :govuk_editor)
    edition = AnswerEdition.find_or_create_from_panopticon_data(artefact.id, user1)

    assert_not artefact.any_editions_published?

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

    assert_not artefact.nil?
    assert_equal "video", artefact.kind
  end

  test "should archive all editions when archived" do
    artefact = FactoryBot.create(:artefact, state: "live")
    editions = %w[draft ready published archived].map do |state|
      FactoryBot.create(:programme_edition, panopticon_id: artefact.id, state: state)
    end
    user1 = FactoryBot.create(:user)

    artefact.update_as(user1, state: "archived")
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
    artefact = FactoryBot.create(:artefact, state: "live")
    edition = FactoryBot.create(:help_page_edition, panopticon_id: artefact.id, state: "published")
    user1 = FactoryBot.create(:user)

    # Make the edition invalid, check that it persisted the invalid state
    edition.title = nil
    edition.save!(validate: false)
    assert_nil edition.reload.title

    artefact.update_as(user1, state: "archived")
    artefact.save!

    assert_equal("archived", edition.reload.state)
  end

  test "should restrict what attributes can be updated on an edition that has an archived artefact" do
    artefact = FactoryBot.create(:artefact, state: "live")
    edition = FactoryBot.create(:programme_edition, panopticon_id: artefact.id, state: "published")
    artefact.state = "archived"
    artefact.save!
    assert_raise RuntimeError do
      edition.update(state: "archived", title: "Shabba", slug: "do-not-allow")
    end
  end

  context "artefact language" do
    should "return english by default" do
      a = FactoryBot.create(:artefact)

      assert_equal "en", a.language
    end

    should "accept welsh language" do
      a = FactoryBot.build(:artefact)
      a.language = "cy"
      a.save!

      a = Artefact.first
      assert_equal "cy", a.language
    end

    should "be welsh? if language is cy" do
      artefact = FactoryBot.build(:artefact, language: "cy")
      assert artefact.welsh?
    end

    should "reject a language which is not english or welsh" do
      a = FactoryBot.build(:artefact)
      a.language = "pirate"

      assert_not a.valid?
    end
  end

  should "have an archived? helper method" do
    published_artefact = FactoryBot.create(:artefact, slug: "scooby", state: "live")
    archived_artefact = FactoryBot.create(:artefact, slug: "doo", state: "archived")

    assert_not published_artefact.archived?
    assert archived_artefact.archived?
  end

  context "#exact_route?" do
    context "for artefacts without a latest edition" do
      should "be true if its owning_app is not publisher and it has no prefixes" do
        assert FactoryBot.build(:artefact, :non_publisher, prefixes: []).exact_route?
      end

      should "be false if its owning_app is not publisher and it has prefixes" do
        assert_not FactoryBot.build(:artefact, :non_publisher, prefixes: ["/hats"]).exact_route?
      end

      should "be true if its owning_app is publisher and its kind is that of an exact route edition" do
        assert FactoryBot.build(:artefact, kind: "campaign", prefixes: []).exact_route?
        assert FactoryBot.build(:artefact, kind: "help_page", prefixes: []).exact_route?

        # regardless of prefixes
        assert FactoryBot.build(:artefact, kind: "campaign", prefixes: ["/hats"]).exact_route?
        assert FactoryBot.build(:artefact, kind: "help_page", prefixes: ["/shoes"]).exact_route?
      end

      should "be false if its owning_app is not publisher and its kind is not that of an exact route edition" do
        assert_not FactoryBot.build(:artefact, kind: "answer", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "completed_transaction", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "guide", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "licence", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "local_transaction", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "place", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "programme", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "simple_smart_answer", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "transaction", prefixes: []).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "video", prefixes: []).exact_route?

        # regardless of prefixes
        assert_not FactoryBot.build(:artefact, kind: "answer", prefixes: ["/hats"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "completed_transaction", prefixes: ["/scarves"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "guide", prefixes: ["/underwear"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "licence", prefixes: ["/jumpers"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "local_transaction", prefixes: ["/gloves"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "place", prefixes: ["/belts"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "programme", prefixes: ["/socks"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "simple_smart_answer", prefixes: ["/onesies"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "transaction", prefixes: ["/scarves"]).exact_route?
        assert_not FactoryBot.build(:artefact, kind: "video", prefixes: ["/all-other-clothing"]).exact_route?
      end
    end

    context "for artefacts with a latest edition" do
      should "delegate to it" do
        latest_edition = mock
        artefact = FactoryBot.build(:artefact)
        artefact.stubs(:latest_edition).returns(latest_edition)

        latest_edition.expects(:exact_route?).returns true
        assert artefact.exact_route?

        latest_edition.expects(:exact_route?).returns false
        assert_not artefact.exact_route?
      end
    end
  end
end
