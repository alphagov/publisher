namespace :temporary_data_hygiene do
  desc "Fix redirect URL for unpublished document /disposal-of-dredged-material-at-sea"
  task redirect_dredged_material: :environment do
    current_user = User.find("5bfc0db3e5274a7e7111a5d7") # Bruce Bolt

    edition = Edition.find_by(slug: "disposal-of-dredged-material-at-sea", state: "archived")
    edition.artefact.update!(redirect_url: "/guidance/do-i-need-a-marine-licence")

    UnpublishService.call(edition.artefact, current_user, edition.artefact.redirect_url)
  end
end
