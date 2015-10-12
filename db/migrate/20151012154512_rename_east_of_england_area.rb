class RenameEastOfEnglandArea < Mongoid::Migration
  def self.up
    # Editing of an edition with an Archived artefact is not allowed
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    BusinessSupportEdition.where(areas: "east-of-england").each do |edition|
      edition.areas = edition.areas.map { |area_slug|
        area_slug == "east-of-england" ? "eastern" : area_slug
      }

      edition.save!(validate: false) # Published editions can't be edited.
    end
  end

  def self.down
    # This was a lossy migration. There were already plenty of
    # BusinessSupportEditions with the area "eastern", which we now can't
    # differentiate from our updated fields :)
  end
end
