require "test_helper"

def merge_attributes(original, *update_hashes)
  # Merge multiple attribute hashes: this also differs from Hash#merge in that
  # it converts symbolic keys to strings
  if update_hashes.empty?
    return original
  else
    first_update, *other_updates = update_hashes
    updated = first_update.reduce(original) do |old, pair|
      key, value = pair
      old.merge(key.to_s => value)
    end
    merge_attributes(updated, *other_updates)
  end
end

class ArtefactActionTest < ActiveSupport::TestCase

  DEFAULTS = {
    "active" => false,
    "need_ids" => [],
    "state" => "draft",
    "paths" => [],
    "prefixes" => [],
    "language" => "en",
  }

  def base_fields
    {
      slug: "an-artefact",
      name: "An artefact",
      kind: "answer",
      owning_app: "publisher"
    }
  end

  def setup
    @artefact = Artefact.create!(base_fields)
  end

  test "a new artefact should have a create action" do
    @artefact.reload

    assert_equal 1, @artefact.actions.size
    action = @artefact.actions.first
    assert_equal "create", action[:action_type]
    assert_equal merge_attributes(DEFAULTS, base_fields), action.snapshot
    assert action.created_at, "Action has no creation timestamp"
  end

  test "an updated artefact should have two actions" do
    @artefact.description = "An artefact of shining wonderment."
    @artefact.save!
    @artefact.reload

    assert_equal 2, @artefact.actions.size
    assert_equal ["create", "update"], @artefact.actions.map(&:action_type)
    create_snapshot = merge_attributes(DEFAULTS, base_fields)
    update_snapshot = create_snapshot.merge("description" => @artefact.description)
    assert_equal create_snapshot, @artefact.actions[0].snapshot
    assert_equal update_snapshot, @artefact.actions[1].snapshot
    @artefact.actions.each do |action|
      assert action.created_at, "Action has no creation timestamp"
    end
  end

  test "saving with no tracked changes will not create a new snapshot" do
    @artefact.updated_at = Time.zone.now + 5.minutes
    @artefact.save!
    assert_equal 1, @artefact.actions.size
  end

  test "updating attributes as a user should record a user action" do
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    @artefact.update_attributes_as user, updates
    @artefact.reload

    assert_equal "Shiny shiny description", @artefact.description
    assert_equal 2, @artefact.actions.size
    assert_equal ["create", "update"], @artefact.actions.map(&:action_type)
    assert_equal user, @artefact.actions.last.user
    assert_equal(
        merge_attributes(DEFAULTS, base_fields, updates),
        @artefact.actions.last.snapshot
    )
  end

  test "saving a task should record the task action" do
    @artefact.description = "Updated automatically"
    @artefact.save_as_task!('TaggingUpdater')
    @artefact.reload

    assert_equal 2, @artefact.actions.size
    assert_equal ["create", "update"], @artefact.actions.map(&:action_type)

    assert_equal 'TaggingUpdater', @artefact.actions.last.task_performed_by
    assert_nil @artefact.actions.last.user
  end

  test "saving as a user should record a user action" do
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    @artefact.description = updates[:description]
    @artefact.save_as user
    @artefact.reload

    assert_equal "Shiny shiny description", @artefact.description
    assert_equal 2, @artefact.actions.size
    assert_equal ["create", "update"], @artefact.actions.map(&:action_type)
    assert_equal user, @artefact.actions.last.user
    assert_equal(
        merge_attributes(DEFAULTS, base_fields, updates),
        @artefact.actions.last.snapshot
    )
  end

  test "saving as a user with an action type" do
    user = FactoryGirl.create :user
    updates = {description: "Shiny shiny description"}
    @artefact.description = updates[:description]
    @artefact.save_as user, action_type: "awesome"
    @artefact.reload

    assert_equal user, @artefact.actions.last.user
    assert_equal "awesome", @artefact.actions.last.action_type
  end

end
