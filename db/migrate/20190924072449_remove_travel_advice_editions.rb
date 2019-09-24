class RemoveTravelAdviceEditions < Mongoid::Migration
  def self.up
    TravelAdviceEdition.delete_all
    Artefact.where(kind: "travel-advice").delete_all
  end

  def self.down
    raise Mongoid::IrreversibleMigration
  end
end
