class AmendBsfSectors < Mongoid::Migration
  def self.up
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
    BusinessSupport::Sector.where(slug: "wholesale-and-retail").update(name: "Wholesale, retail and repairs")
  end

  def self.down
  end
end