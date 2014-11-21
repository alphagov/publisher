require "csv"
require "gds_api/imminence"

class BusinessSupportAreasImporter

  def self.run(data_path)
    count = 0
    puts data_path
    CSV.foreach(data_path, :headers => true) do |row|
      # Find each BusinessSupportEdition by slug
      if bs_editions = BusinessSupportEdition.where(:state.ne => "archived", :slug => row["slug"])
        bs_editions.each do |bs_edition|
          unless bs_edition.artefact.state == "archived"
            # Convert regions to region slugs
            regions = row["regions"].split(",")
            regions.map!(&:strip)
            regions.map!(&:parameterize)
            # Verify regional slugs for this Edition
            regions.keep_if { |r| imminence_areas.include?(r) }
            # Overwrite areas for Edition
            puts "Updating #{bs_edition.slug} with areas: #{regions}"
            count += 1 if bs_edition.update_attribute(:areas, regions)
          end
        end
      end
    end
    puts "#{count} BusinessSupportEditions updated"
  end

private

  def self.imminence_areas
    @imminence_areas ||= %w(EUR CTY DIS LBO LGD MTD UTA).map { |t| area_slugs(t) }.flatten
  end

  def self.area_slugs(area_type)
    imminence_api.areas_for_type(area_type).results.map(&:slug)
  end

  def self.imminence_api
    @imminence_api ||= GdsApi::Imminence.new(Plek.current.find("imminence"))
  end
end
