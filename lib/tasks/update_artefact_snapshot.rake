desc "Update artefact snapshots - replace old Mongo ID with new Postgres ID after migration complete"
task update_artefact_snapshot: :environment do |_t, _args|
  ArtefactSnapshotUpdater.new.call
end
