namespace :publishing_api do
  task republish_content: [:environment] do
    puts "Scheduling republishing of #{Edition.published.count} editions"

    RepublishContent.schedule_republishing

    puts "Scheduling finished"
  end

  task :republish_by_format, [:format] => :environment do |_, args|
    editions = Artefact.published_edition_ids_for_format(args[:format])

    puts "Scheduling republishing of #{editions.count} #{args[:format]}s."

    editions.each do |edition_id|
      PublishingAPIRepublisher.perform_async(edition_id)
      print "."
    end

    puts "\nScheduling finished"
  end
end
