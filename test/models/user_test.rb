require "test_helper"
require "gds-sso/lint/user_test"

class GDS::SSO::Lint::UserTest
  def user_class
    ::User
  end
end

class UserTest < ActiveSupport::TestCase
  def setup
    @artefact = FactoryGirl.create(:artefact)
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
    disabled = FactoryGirl.create(:user, disabled: true)

    FactoryGirl.create(:user).unset(:disabled)
    FactoryGirl.create(:user, disabled: false)
    FactoryGirl.create(:user, disabled: nil)

    assert_equal 3, User.enabled.count
    refute User.enabled.include? disabled
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
          "permissions" => ["signin"],
          "disabled" => false,
        }
      }
    }
    user = User.find_for_gds_oauth(auth_hash).reload
    assert_equal "1234abcd", user.uid
    assert_equal "user@example.com", user.email
    assert_equal "Luther Blisset", user.name
    assert_equal(["signin"], user.permissions)
    refute user.disabled?
  end

  test "should find and update the user with oauth params" do
    attributes = {uid: "1234abcd", name: "Old", email: "old@m.com",
        permissions: ["everything"]}
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

  test "should create insecure gravatar URL" do
    user = User.new(email: "User@example.com")
    expected = "http://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af"
    assert_equal expected, user.gravatar_url
  end

  test "should create secure gravatar URL" do
    user = User.new(email: "user@example.com")
    expected = "https://secure.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af"
    assert_equal expected, user.gravatar_url(ssl: true)
  end

  test "should add escaped s parameter if supplied" do
    user = User.new(email: "user@example.com")
    expected = "http://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?s=foo+bar"
    assert_equal expected, user.gravatar_url(s: "foo bar")
  end

  test "creating a transaction with the initial details creates a valid transaction" do
    user = User.create(:name => "bob")
    trans = user.create_edition(:transaction, title: "test", slug: "test", panopticon_id: @artefact.id)
    assert trans.valid?
  end

  test "user can't okay a publication they've sent for review" do
    user = User.create(:name => "bob")

    trans = user.create_edition(:transaction, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    request_review(user, trans)
    refute approve_review(user, trans)
  end

  test "Edition becomes assigned to user when user is assigned an edition" do
    boss_user = FactoryGirl.create(:user, :name => "Mat")
    worker_user = FactoryGirl.create(:user, :name => "Grunt")

    publication = boss_user.create_edition(:answer, title: "test answer", slug: "test", panopticon_id: @artefact.id)
    boss_user.assign(publication, worker_user)
    publication.save
    publication.reload

    assert_equal(worker_user, publication.assigned_to)
  end

  test "Edition can be unassigned" do
    boss_user = FactoryGirl.create(:user, :name => "Mat")
    worker_user = FactoryGirl.create(:user, :name => "Grunt")

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
