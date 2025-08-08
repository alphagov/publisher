require "test_helper"

def merge_attributes(original, *update_hashes)
  # Merge multiple attribute hashes: this also differs from Hash#merge in that
  # it converts symbolic keys to strings
  if update_hashes.empty?
    original
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
    "state" => "draft",
    "paths" => [],
    "prefixes" => [],
    "language" => "en",
  }.freeze

  def base_fields
    {
      slug: "an-artefact",
      name: "An artefact",
      kind: "answer",
      owning_app: "publisher",
      description: "",
      redirect_url: nil,
      rendering_app: nil,
      publication_id: nil,
      public_timestamp: nil,
      latest_change_note: nil,
      content_id: nil,
      mongo_id: nil,
    }
  end

  def setup
    @artefact = Artefact.create!(base_fields)
  end

  test "a new artefact should have a create action" do
    @artefact.reload
    assert_equal 1, @artefact.artefact_actions.size
    action = @artefact.artefact_actions.first
    assert_equal "create", action[:action_type]
    assert_equal merge_attributes(DEFAULTS, base_fields), action.snapshot
    assert action.created_at, "Action has no creation timestamp"
  end

  test "an updated artefact should have two actions" do
    @artefact.description = "An artefact of shining wonderment."
    @artefact.save!
    @artefact.reload

    assert_equal 2, @artefact.artefact_actions.size
    assert_equal %w[create update], @artefact.artefact_actions.map(&:action_type)
    create_snapshot = merge_attributes(DEFAULTS, base_fields)
    update_snapshot = create_snapshot.merge("description" => @artefact.description)
    assert_equal create_snapshot, @artefact.artefact_actions[0].snapshot
    assert_equal update_snapshot, @artefact.artefact_actions[1].snapshot
    @artefact.artefact_actions.each do |action|
      assert action.created_at, "Action has no creation timestamp"
    end
  end

  test "saving with no tracked changes will not create a new snapshot" do
    @artefact.updated_at = Time.zone.now + 5.minutes
    @artefact.save!
    assert_equal 1, @artefact.artefact_actions.size
  end

  test "updating attributes as a user should record a user action" do
    user = FactoryBot.create :user
    updates = { description: "Shiny shiny description" }
    @artefact.update_as user, updates
    @artefact.reload

    assert_equal "Shiny shiny description", @artefact.description
    assert_equal 2, @artefact.artefact_actions.size
    assert_equal %w[create update], @artefact.artefact_actions.map(&:action_type)
    assert_equal user, @artefact.artefact_actions.last.user
    assert_equal(
      merge_attributes(DEFAULTS, base_fields, updates),
      @artefact.artefact_actions.last.snapshot,
    )
  end

  test "saving a task should record the task action" do
    @artefact.description = "Updated automatically"
    @artefact.save_as_task!("TaggingUpdater")
    @artefact.reload

    assert_equal 2, @artefact.artefact_actions.size
    assert_equal %w[create update], @artefact.artefact_actions.map(&:action_type)

    assert_equal "TaggingUpdater", @artefact.artefact_actions.last.task_performed_by
    assert_nil @artefact.artefact_actions.last.user
  end

  test "saving as a user should record a user action" do
    user = FactoryBot.create :user
    updates = { description: "Shiny shiny description" }
    @artefact.description = updates[:description]
    @artefact.save_as user
    @artefact.reload

    assert_equal "Shiny shiny description", @artefact.description
    assert_equal 2, @artefact.artefact_actions.size
    assert_equal %w[create update], @artefact.artefact_actions.map(&:action_type)
    assert_equal user, @artefact.artefact_actions.last.user
    assert_equal(
      merge_attributes(DEFAULTS, base_fields, updates),
      @artefact.artefact_actions.last.snapshot,
    )
  end

  test "saving as a user with an action type" do
    user = FactoryBot.create :user
    updates = { description: "Shiny shiny description" }
    @artefact.description = updates[:description]
    @artefact.save_as user, action_type: "awesome"
    @artefact.reload

    assert_equal user, @artefact.artefact_actions.last.user
    assert_equal "awesome", @artefact.artefact_actions.last.action_type
  end
end
