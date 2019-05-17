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

    FactoryBot.create(:user).unset(:disabled)
    FactoryBot.create(:user, disabled: false)
    FactoryBot.create(:user, disabled: nil)

    assert_equal 3, User.enabled.count
    assert_not User.enabled.include? disabled
  end

  test "should create new user with oauth params" do
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "uid"     => "1234abcd",
        "email"   => "user@example.com",
        "name"    => "Luther Blisset"
      },
      "extra" => {
        "user" => {
          "permissions" => %w[signin],
          "disabled" => false,
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "user@example.com", user.email
    assert_equal "Luther Blisset", user.name
    assert_equal(%w[signin], user.permissions)
    assert_not user.disabled?
  end

  test "should find and update the user with oauth params" do
    attributes = { uid: "1234abcd", name: "Old", email: "old@m.com",
        permissions: %w[everything] }
    User.create!(attributes)
    auth_hash = {
      "uid" => "1234abcd",
      "info" => {
        "email"   => "new@m.com",
        "name"    => "New"
      },
      "extra" => {
        "user" => {
          "permissions" => [],
          "disabled" => true
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "new@m.com", user.email
    assert_equal "New", user.name
    assert_equal([], user.permissions)
    assert user.disabled?
  end

  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(name: "bob")
    trans = user.create_edition(:transaction, title: "test", slug: "test", panopticon_id: @artefact.id)
    assert trans.valid?
  end

  test "user can't okay a publication they've sent for review" do
    user = User.create(name: "bob")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    request_review(user, trans)
    assert_not approve_review(user, trans)
  end

  test "Edition becomes assigned to user when user is assigned an edition" do
    boss_user = FactoryBot.create(:user, name: "Mat")
    worker_user = FactoryBot.create(:user, name: "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    boss_user.assign(publication, worker_user)
    publication.save
    publication.reload

    assert_equal(worker_user, publication.assigned_to)
  end

  test "Edition can be unassigned" do
    boss_user = FactoryBot.create(:user, name: "Mat")
    worker_user = FactoryBot.create(:user, name: "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    boss_user.assign(publication, worker_user)
    publication.save
    publication.reload

    assert_equal(worker_user, publication.assigned_to)

    boss_user.unassign(publication)
    publication.save
    publication.reload

    assert_nil publication.assigned_to
  end
end
