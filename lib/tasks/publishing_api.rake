namespace :publishing_api do
  task :republish_content => [:environment] do
    puts "Scheduling republishing of #{Edition.published.count} editions"

    RepublishContent.schedule_republishing

    puts "Scheduling finished"
  end
end
