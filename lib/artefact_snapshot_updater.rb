class ArtefactSnapshotUpdater
  def call
    count = 0
    ArtefactAction.all.each do |artefact_action|
      artefact_ids = artefact_action.snapshot["artefact_ids"]
      if artefact_ids.present?
        new_artefact_ids = []
        artefact_ids.each do |artefact_id|
          artefact_id = Artefact.where(mongo_id: artefact_id["$oid"]) if artefact_id.is_a?(Hash)
          if artefact_id.present?
            new_artefact_ids << Artefact.where(mongo_id: artefact_id["$oid"]).first.id
          end
        end
        artefact_action.snapshot["artefact_ids"] = new_artefact_ids
      end

      related_artefact_ids = artefact_action.snapshot["related_artefact_ids"]
      if related_artefact_ids.present?
        new_related_artefact_ids = []
        related_artefact_ids.each do |related_artefact_id|
          artefact_id = Artefact.where(mongo_id: related_artefact_id["$oid"]) if related_artefact_id.is_a?(Hash)
          if artefact_id.present?
            new_related_artefact_ids << Artefact.where(mongo_id: related_artefact_id["$oid"]).first.id
          end
        end
        artefact_action.snapshot["related_artefact_ids"] = new_related_artefact_ids
      end

      puts "saved file #{count}"
      count += 1
      artefact_action.save!
    end
  end

private

  def log(*args)
    line = args.prepend(Time.zone.now.iso8601).join("\t")
    Rails.logger.info line
  end
end
