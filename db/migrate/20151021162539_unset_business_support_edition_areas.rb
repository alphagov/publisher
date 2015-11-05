class UnsetBusinessSupportEditionAreas < Mongoid::Migration
  def self.up
    BusinessSupportEdition.all.each do |edition|
      edition.unset(:areas)
      puts "unset areas for #{edition.slug}"
    end
  end

  def self.down
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    BusinessSupportEdition.all.each do |edition|
      edition.areas = Area.areas_for_edition(edition).map(&:slug).compact
      puts "set areas for #{edition.slug}"

      edition.save!(validate: false) # Published editions can't be edited.
    end
  end
end
