namespace :publishing_api do
  task :republish_content => [:environment] do
    puts "Scheduling republishing of #{Edition.published.count} editions"

    Edition.published.each do |edition|
      PublishingAPINotifier.perform_async(edition.id, "republish")
    end

    puts "Scheduling finished"
  end
end
