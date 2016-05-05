class FixGssCodesForSomeCouncilsInExistingSupportSchemes < Mongoid::Migration
  def self.up
    # "Editing of an edition with an Archived artefact is not allowed".
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    northumberland_schemes = BusinessSupportEdition.where(area_gss_codes: "E06000048")
    northumberland_schemes.each do |ns|
      ns.area_gss_codes.delete("E06000048")
      ns.area_gss_codes.push("E06000057")
      ns.save!(validate: false)
    end

    gateshead_schemes = BusinessSupportEdition.where(area_gss_codes: "E08000020")
    gateshead_schemes.each do |gs|
      gs.area_gss_codes.delete("E08000020")
      gs.area_gss_codes.push("E08000037")
      gs.save!(validate: false)
    end

    east_hertfordshire_schemes = BusinessSupportEdition.where(area_gss_codes: "E07000097")
    east_hertfordshire_schemes.each do |ehs|
      ehs.area_gss_codes.delete("E07000097")
      ehs.area_gss_codes.push("E07000242")
      ehs.save!(validate: false)
    end

    stevenage_schemes = BusinessSupportEdition.where(area_gss_codes: "E07000101")
    stevenage_schemes.each do |ss|
      ss.area_gss_codes.delete("E07000101")
      ss.area_gss_codes.push("E07000243")
      ss.save!(validate: false)
    end
  end

  def self.down
  end
end
