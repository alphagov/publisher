class BusinessSupportLocationMigrator

  REGIONAL_MAPPINGS_ENGLAND = {
    "london"                    => "london",
    "north-west"                => "north-west",
    "north-east"                => "north-east",
    "east-midlands"             => "east-midlands",
    "west-midlands"             => "west-midlands",
    "yorkshire-and-the-humber"  => "yorkshire-and-the-humber",
    "south-west"                => "south-west",
    "south-east"                => "south-east",
    "east-of-england"           => "eastern"
  }

  REGIONAL_MAPPINGS_UK = {
    "northern-ireland"  => "northern-ireland",
    "wales"             => "wales",
    "scotland"          => "scotland",
    "england"           => REGIONAL_MAPPINGS_ENGLAND.values
  }.merge(REGIONAL_MAPPINGS_ENGLAND)

  def self.run
    BusinessSupportEdition.excludes(state: 'archived').order_by(:slug).each do |bs|
      next if bs.artefact.state == 'archived'

      area_slugs = []
      bs.locations.each do |loc|
        area_slug = REGIONAL_MAPPINGS_UK[loc]
        if area_slug
          area_slugs << area_slug
        else
          puts "Area slug not found for location '#{loc}'"
        end
      end

      area_slugs = area_slugs.flatten.uniq.map(&:to_s)
      bs.areas = area_slugs

      if bs.save(validate: false)
        puts "Saved areas #{area_slugs} for #{bs.slug}, locations : #{bs.locations}"
      else
        puts "ERROR saving #{bs.slug}"
      end
    end
  end
end
