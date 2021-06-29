desc "Remove Landlord Immigration Check page"

task remove_landlord_immigration_check: :environment do
  Artefact.find_by(slug: "landlord-immigration-check").delete
end
