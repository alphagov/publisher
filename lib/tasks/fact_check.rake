namespace :fact_check do
  desc "Revoke and renew draft preview links for given edition ids"
  task :revoke_and_renew_draft_links, [:edition_id] => :environment do |_t, args|
    edition_ids = args[:edition_id].split(",")

    edition_ids.each do |id|
      edition = Edition.find_by(id: id)

      edition.auth_bypass_id = SecureRandom.uuid
      edition.save!

      UpdateWorker.perform_async(id)
      FactCheckManagerApiService.update_fact_check_content(edition)
    end
  end
end
