class FixGssCodesForScottishCouncilsInExistingSupportSchemes < Mongoid::Migration
  def self.up
    Edition.skip_callback(:save, :before, :check_for_archived_artefact)

    fife_schemes = BusinessSupportEdition.where(area_gss_codes: "S12000015")
    fife_schemes.each do |fi|
      fi.area_gss_codes.delete("S12000015")
      fi.area_gss_codes.push("S12000047")
      fi.save!(validate: false)
    end

    perth_kinross_schemes = BusinessSupportEdition.where(area_gss_codes: "S12000024")
    perth_kinross_schemes.each do |pk|
      pk.area_gss_codes.delete("S12000024")
      pk.area_gss_codes.push("S12000048")
      pk.save!(validate: false)
    end
  end

  def self.down
  end
end
