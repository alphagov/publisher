class RemoveBsfSectors < Mongoid::Migration
  def self.up
    BusinessSupport::Sector.where(slug: "information-communication-and-media").destroy
    BusinessSupport::Sector.where(slug: "service-industries").destroy
    BusinessSupport::Sector.where(slug: "travel-and-leisure").destroy
  end

  def self.down
  end
end