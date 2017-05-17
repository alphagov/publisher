class UnsetSectionFieldInEditions < Mongoid::Migration
  def self.up
    Edition.all.each { |e| e.unset(:section) }
  end

  def self.down
    Edition.all.each { |e| e.set(:section, e.artefact.section) }
  end
end
