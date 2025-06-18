require "test_helper"
require "gds-sso/lint/user_test"

class GDS::SSO::Lint::UserTest
  def user_class
    ::User
  end
end

class UserTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryBot.create(:artefact)
  end

  test "#has_editor_permissions? is true with govuk_editor and non-Welsh editions" do
    govuk_editor = FactoryBot.create(:user, :govuk_editor)
    edition = FactoryBot.create(:edition)

    assert govuk_editor.has_editor_permissions?(edition)
  end

  test "#has_editor_permissions? is true with govuk_editor and Welsh editions" do
    govuk_editor = FactoryBot.create(:user, :govuk_editor)
    welsh_edition = FactoryBot.create(:edition, :welsh)

    assert govuk_editor.has_editor_permissions?(welsh_edition)
  end

  test "#has_editor_permissions? is false with welsh_editor and non-Welsh editions" do
    welsh_editor = FactoryBot.create(:user, :welsh_editor)
    edition = FactoryBot.create(:edition)

    assert_not welsh_editor.has_editor_permissions?(edition)
  end

  test "#has_editor_permissions? is true with welsh_editor and Welsh editions" do
    welsh_editor = FactoryBot.create(:user, :welsh_editor)
    welsh_edition = FactoryBot.create(:edition, :welsh)

    assert welsh_editor.has_editor_permissions?(welsh_edition)
  end

  test "is welsh_editor? if permissions include welsh_editor" do
    user = FactoryBot.create(:user, :welsh_editor)
    assert user.welsh_editor?
  end

  test "#gds_editor? is true if user's organisation is GDS" do
    user = FactoryBot.create(:user, organisation_content_id: PublishService::GDS_ORGANISATION_ID)

    assert user.gds_editor?
  end

  test "#gds_editor? is false if user's organisation is not GDS" do
    user = FactoryBot.create(:user, organisation_slug: "some-other-org", organisation_content_id: "some-other-org-id")

    assert_not user.gds_editor?
  end

  test "#skip_review? is true if user may skip reviews" do
    user = FactoryBot.create(:user, :skip_review)

    assert user.skip_review?
  end

  test "#skip_review? is false if user may not skip reviews" do
    user = FactoryBot.create(:user)

    assert_not user.skip_review?
  end

  test "should convert to string using name by preference" do
    user = User.new(name: "Bob", email: "user@example.com")
    assert_equal "Bob", user.to_s
  end

  test "should convert to string using email if name if missing" do
    user = User.new(email: "user@example.com")
    assert_equal "user@example.com", user.to_s
  end

  test "should convert to empty string if name and email are missing" do
    user = User.new
    assert_equal "", user.to_s
  end

  test "should return enabled users" do
    disabled = FactoryBot.create(:user, disabled: true)

    FactoryBot.create(:user, disabled: false)
    FactoryBot.create(:user, disabled: false)
    FactoryBot.create(:user, disabled: nil)

    assert_equal 3, User.enabled.count
    assert_not User.enabled.include? disabled
  end

  test "should create new user with oauth params" do
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "uid" => "1234abcd",
        "email" => "user@example.com",
        "name" => "Luther Blisset",
      },
      "extra" => {
        "user" => {
          "permissions" => %w[signin],
          "disabled" => false,
        },
      },
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "user@example.com", user.email
    assert_equal "Luther Blisset", user.name
    assert_equal(%w[signin], user.permissions)
    assert_not user.disabled?
  end

  test "should find and update the user with oauth params" do
    attributes = { uid: "1234abcd",
                   name: "Old",
                   email: "old@m.com",
                   permissions: %w[everything] }
    User.create!(attributes)
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "email" => "new@m.com",
        "name" => "New",
      },
      "extra" => {
        "user" => {
          "permissions" => [],
          "disabled" => true,
        },
      },
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "new@m.com", user.email
    assert_equal "New", user.name
    assert_equal([], user.permissions)
    assert user.disabled?
  end

  test "creating a transaction with the initial details creates a valid transaction" do
    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    trans = user.create_edition(:transaction, title: "test", slug: "test", panopticon_id: @artefact.id)
    assert trans.valid?
  end

  test "user can't okay a publication they've sent for review" do
    user = FactoryBot.create(:user, :govuk_editor, name: "bob")
    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    request_review(user, trans)
    assert_not approve_review(user, trans)
  end

  test "Edition becomes assigned to user when user is assigned an edition" do
    boss_user = FactoryBot.create(:user, :govuk_editor, name: "Mat")
    worker_user = FactoryBot.create(:user, :govuk_editor, name: "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    boss_user.assign(publication, worker_user)
    publication.save!
    publication.reload

    assert_equal(worker_user, publication.assigned_to)
  end

  test "Edition can be unassigned" do
    boss_user = FactoryBot.create(:user, :govuk_editor, name: "Mat")
    worker_user = FactoryBot.create(:user, :govuk_editor, name: "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    boss_user.assign(publication, worker_user)
    publication.save!
    publication.reload

    assert_equal(worker_user, publication.assigned_to)

    boss_user.unassign(publication)
    publication.save!
    publication.reload

    assert_nil publication.assigned_to
  end
end
