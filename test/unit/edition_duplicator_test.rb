require 'test_helper'
require 'edition_duplicator'

# We might want to consider decoupling this test from
# the user and the edition, but for now at least those
# are the clear, minimal dependencies.
class EditionDuplicatorTest < ActiveSupport::TestCase

  setup do
    @laura = FactoryGirl.create(:user)
    @fred  = FactoryGirl.create(:user)
    @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    stub_register_published_content
  end

  def publish_item(item, actor)
    item.state = 'ready'
    actor.publish(item, command: 'Publishing this')
  end

  test "should assign after creating new edition" do
    publish_item(@guide, @laura)

    command = EditionDuplicator.new(@guide, @laura)
    assert command.duplicate(nil, @fred)

    assert_equal @fred, command.new_edition.assigned_to
  end

  test "should not assign after creating a new edition if assignment is blank" do
    publish_item(@guide, @laura)

    command = EditionDuplicator.new(@guide, @laura)
    command.duplicate

    assert_nil command.new_edition.assigned_to
  end

  test "can provide an appropriate error message if new edition failed" do
    @laura.stubs(:new_version).with(@guide, nil).returns(false)

    command = EditionDuplicator.new(@guide, @laura)
    refute command.duplicate(nil, @fred)

    assert_equal "Failed to create new edition: couldn't initialise", command.error_message
  end

end