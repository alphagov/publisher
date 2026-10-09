namespace :fact_check do
  desc "Revoke and renew draft preview links for given edition ids"
  task :revoke_and_renew_draft_links, [:edition_ids] => :environment do |_t, args|
    # Rake splits "task[id1,id2]" on commas, so each id is a separate argument
    edition_ids = args.to_a
    editions = Edition.where(id: edition_ids)

    editions.each do |edition|
      edition.update!(auth_bypass_id: SecureRandom.uuid)
      UpdateWorker.perform_async(edition.id)
      Services.fact_check_manager_api.patch_update_content(**FactCheckRequestForm.new(edition:).update_content_payload)
    rescue GdsApi::HTTPNotFound
      puts "Edition #{edition.id} has no Fact Check Manager request, so only its draft link was renewed"
    end
    puts "Renewed draft preview links for #{editions.size} edition(s)"

    missing_ids = edition_ids - editions.map(&:id)
    abort "No editions found for edition ids: #{missing_ids.join(', ')}" if missing_ids.any?
  end
end
