class AddNewBsfSectors < Mongoid::Migration
  def self.up
    BusinessSupport::Sector.create(slug: "post-couriers-telecommunication", name: "Post, couriers and telecommunication")
    BusinessSupport::Sector.create(slug: "media-advertising-publishing", name: "Media, advertising and publishing")
    BusinessSupport::Sector.create(slug: "motor-retail-repair-wholesale", name: "Motor retail, repair and wholesale")
    BusinessSupport::Sector.create(slug: "arts-entertainment-sport", name: "Arts, entertainment and sport")
    BusinessSupport::Sector.create(slug: "call-centers-administrative-services", name: "Call centres and administrative services")
    BusinessSupport::Sector.create(slug: "tradespeople-cleaners-maintenance", name: "Tradespeople, cleaners and maintenance")
    BusinessSupport::Sector.create(slug: "professional-scientific-technical", name: "Professional, scientific and technical")
  end

  def self.down
  end
end