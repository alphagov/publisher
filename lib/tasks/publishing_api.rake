namespace :publishing_api do
  task republish_content: [:environment] do
    republish Edition.published
    republish_draft Edition.draft_in_publishing_api
  end

  task :republish_by_format, [:format] => :environment do |_, args|
    format_editions = Edition.by_format(args[:format])

    republish format_editions.published
    republish_draft format_editions.draft_in_publishing_api
  end

  def republish(editions)
    puts
    puts "Scheduling republishing of #{editions.count} editions"

    editions.each do |edition|
      PublishingAPIRepublisher.perform_async(edition.id.to_s)
      print "."
    end

    puts
    puts "Scheduling finished"
  end

  def republish_draft(draft_editions)
    puts
    puts "Scheduling republishing of #{draft_editions.count} draft editions"

    draft_editions.each do |draft_edition|
      PublishingAPIUpdater.perform_async(draft_edition.id.to_s)
      print "."
    end

    puts
    puts "Scheduling finished"
  end
end
