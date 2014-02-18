class RemoveSpecialistDocuments < Mongoid::Migration
  def self.up
    Edition.where(:_type => "SpecialistDocumentEdition").destroy_all
  end

  def self.down
    # No down, this is destructive
  end
end
