class FixIncorrectLgslCodeInArchivedLocalTransactionEdition < Mongoid::Migration
  def self.up
    # "Editing of an edition with an Archived artefact is not allowed".
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    # LGSL Code 1743 entered incorrectly as 1473 (see: https://github.com/alphagov/publisher/commit/5411e984203fe57149089f06961ca76fe201db46)
    care_act_editions = LocalTransactionEdition.where(lgsl_code: 1473)
    care_act_editions.each do |edition|
      edition.lgsl_code = 1743
      edition.save!(validate: false)
    end
  end

  def self.down
  end
end
