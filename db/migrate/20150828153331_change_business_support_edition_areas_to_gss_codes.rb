class ChangeBusinessSupportEditionAreasToGssCodes < Mongoid::Migration
  def self.up
    # Editing of an edition with an Archived artefact is not allowed
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    BusinessSupportEdition.all.each do |edition|
      edition.area_gss_codes = Area.areas_for_edition(edition).map { |area|
        area.codes["gss"]
      }.compact

      edition.save!(validate: false) # Published editions can't be edited.
    end
  end

  def self.down
    # If this needs rolling back permanently, the area_gss_codes field should
    # probably just be removed from GOV.UK Content Models.

    BusinessSupportEdition.all.each do |edition|
      edition.unset(:area_gss_codes)
    end
  end
end
