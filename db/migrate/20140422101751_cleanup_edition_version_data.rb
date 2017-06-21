class CleanupEditionVersionData < Mongoid::Migration
  def self.fixup_versions(artefact_id, duplicated_version, correct_id)
    unless Edition.where(panopticon_id: artefact_id, version_number: duplicated_version).count > 1
      puts "Editions for #{artefact_id} version #{duplicated_version} look correct, skipping"
      return false
    end

    puts "Incrementing #{artefact_id} versions >= #{duplicated_version}"
    Edition.where(:panopticon_id => artefact_id,
                  :version_number.gte => duplicated_version,
                  :_id.ne => correct_id).each do |ed|
      ed.inc(:version_number, 1)
      if ed.sibling_in_progress.to_i > 0
        ed.inc(:sibling_in_progress, 1)
      end
    end
    true
  end

  def self.up
    fixup_versions('4fa11ce69d5eb5495b000220', 9, '51deb41340f0b61192000486')

    # This one had 2 published versions with version number 1.  This change will preserve
    # the one that's currently being served as the published one.
    updated = fixup_versions('5076c643ed915d119d000037', 1, '519b50fae5274a1bbf00005b')
    if updated && ed = Edition.where(_id: "519b50fae5274a1bbf00005b").first
      ed.set(:state, 'archived')
    end

    # This index has been replaced on the model with a unique index on panopticon_id and version_number
    # Clean it up to avoid unnecessary indices
    Edition.collection.drop_index('panopticon_id_1')
  end

  def self.down
  end
end
