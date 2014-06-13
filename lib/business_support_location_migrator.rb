class BusinessSupportLocationMigrator

  REGIONAL_MAPPINGS_ENGLAND = {
    "london"                    => 9728,
    "north-west"                => 9729,
    "north-east"                => 9734,
    "east-midlands"             => 9727,
    "west-midlands"             => 9731,
    "yorkshire-and-the-humber"  => 9732,
    "south-west"                => 9736,
    "south-east"                => 9733,
    "east-of-england"           => 9726
  }

  REGIONAL_MAPPINGS_UK = {
    "northern-ireland"  => 23204,
    "wales"             => 9735,
    "scotland"          => 9730,
    "england"           => REGIONAL_MAPPINGS_ENGLAND.values
  }.merge(REGIONAL_MAPPINGS_ENGLAND)

  def self.run
    BusinessSupportEdition.excludes(state: 'archived').order_by(:slug).each do |bs|
      next if bs.artefact.state == 'archived'

      area_ids = []
      bs.locations.each do |loc|
        area_id = REGIONAL_MAPPINGS_UK[loc]
        if area_id
          area_ids << area_id
        else
          puts "Area ID not found for location '#{loc}'"
        end
      end

      area_ids = area_ids.flatten.uniq.map(&:to_s)
      bs.areas = area_ids

      if bs.save(validate: false)
        puts "Saved areas #{area_ids} for #{bs.slug}, locations : #{bs.locations})"
      else
        puts "ERROR saving #{bs.slug}"
      end
    end
  end
end
