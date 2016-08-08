class AmendBsfSectors < Mongoid::Migration
  def self.up
    # Amend sector names
    BusinessSupport::Sector.where(slug: "agriculture").update(name: "Agriculture, fishing and forestry")
    BusinessSupport::Sector.where(slug: "business-and-finance").update(name: "Financial services and business consultancy")
    BusinessSupport::Sector.where(slug: "construction").update(name: "Construction")
    BusinessSupport::Sector.where(slug: "education").update(name: "Education")
    BusinessSupport::Sector.where(slug: "health").update(name: "Medical, mental health, addiction and social work")
    BusinessSupport::Sector.where(slug: "hospitality-and-catering").update(name: "Accommodation and food services")
    BusinessSupport::Sector.where(slug: "manufacturing").update(name: "Manufacturing and engineering")
    BusinessSupport::Sector.where(slug: "mining").update(name: "Mining and quarrying")
    BusinessSupport::Sector.where(slug: "real-estate").update(name: "Real estate, renting and property development")
    BusinessSupport::Sector.where(slug: "science-and-technology").update(name: "Research and development")
    BusinessSupport::Sector.where(slug: "transport-and-distribution").update(name: "Transport, travel, storage and distribution")
    BusinessSupport::Sector.where(slug: "utilities").update(name: "Electricity, gas and water supply")
    BusinessSupport::Sector.where(slug: "wholesale-and-retail").update(name: "Wholsale, retail and repairs")

    # Remove sectors
    BusinessSupport::Sector.where(slug: "information-communication-and-media").destroy
    BusinessSupport::Sector.where(slug: "service-industries").destroy
    BusinessSupport::Sector.where(slug: "travel-and-leisure").destroy

    # Create new sectors
    BusinessSupport::Sector.create(slug: "post-couriers-telecommunication", name: "Post, couriers and telecommunication")
    BusinessSupport::Sector.create(slug: "media-advertising-publishing" , name: "Media, advertising and publishing")
    BusinessSupport::Sector.create(slug: "motor-retail-repair-wholesale", name: "Motor retail, repair and wholesale")
    BusinessSupport::Sector.create(slug: "arts-entertainment-sport", name: "Arts, entertainment and sport")
    BusinessSupport::Sector.create(slug: "call-centers-administrative-services", name: "Call centres and administrative services")
    BusinessSupport::Sector.create(slug: "tradespeople-cleaners-maintenance", name: "Tradespeople, cleaners and maintenance")
    BusinessSupport::Sector.create(slug: "professional-scientific-technical", name: "Professional, scientific and technical ")
  end

  def self.down
  end
end