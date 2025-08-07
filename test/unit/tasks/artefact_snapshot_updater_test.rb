require "test_helper"
require "rake"

class ArtefactSnapshotUpdaterTest < ActiveSupport::TestCase
  setup do
    @update_artefact_snapshot = Rake::Task["update_artefact_snapshot"]
    @update_artefact_snapshot.reenable
  end

  should "not update snapshot's related_artefact_ids if no related_artefact_ids exist" do
    FactoryBot.create(:artefact)
    artefact_action = ArtefactAction.first
    artefact_action.snapshot["related_artefact_ids"] = []
    artefact_action.save!

    @update_artefact_snapshot.invoke
    assert_equal [], ArtefactAction.first.snapshot["related_artefact_ids"]
  end

  should "not update snapshot's related_artefact_ids if no related_artefact_ids is nil" do
    FactoryBot.create(:artefact)
    artefact_action = ArtefactAction.first
    artefact_action.snapshot["related_artefact_ids"] = nil
    artefact_action.save!

    @update_artefact_snapshot.invoke

    assert_equal 1, ArtefactAction.count
    assert_equal nil, ArtefactAction.first.snapshot["related_artefact_ids"]
  end

  should "update snapshot's related_artefact_ids mongo_ids with corresponding artefacts postgres ids" do
    artefact1 = FactoryBot.create(:artefact, mongo_id: "artefact1")
    artefact2 = FactoryBot.create(:artefact, mongo_id: "artefact2")
    artefact3 = FactoryBot.create(:artefact, mongo_id: "artefact3")
    FactoryBot.create(:artefact, mongo_id: "artefact4")

    artefact_action = ArtefactAction.last
    artefact_action.snapshot["related_artefact_ids"] = [{ "$oid": artefact1.mongo_id }, { "$oid": artefact2.mongo_id }, { "$oid": artefact3.mongo_id }]
    artefact_action.save!

    @update_artefact_snapshot.invoke

    assert_equal [artefact1.id, artefact2.id, artefact3.id], ArtefactAction.last.snapshot["related_artefact_ids"]
  end
end
