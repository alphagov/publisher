class ChangeLgsl230To107OnLocalTransaction < Mongoid::Migration
  def self.up
    # "Editing of an edition with an Archived artefact is not allowed".
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    sheltered_housing_editions = LocalTransactionEdition.where(lgsl_code: 230)
    sheltered_housing_editions.each do |edition|
      edition.lgsl_code = 107
      edition.save!(validate: false)
    end
  end

  def self.down
  end
end