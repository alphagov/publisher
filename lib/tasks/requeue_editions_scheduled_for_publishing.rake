namespace :editions do
  desc "Re-queue editions scheduled for publishing"
  task :requeue_scheduled_for_publishing => :environment do
    criteria = Edition.with_state("scheduled_for_publishing")
    editions_scheduled_for_publishing_count = criteria.count

    criteria.each do |edition|
      puts "cancelling scheduled publishing of: #{edition.slug}"
      ScheduledPublisher.cancel_scheduled_publishing(edition.id.to_s)
      puts " scheduling publishing of: #{edition.slug}"
      ScheduledPublisher.perform_at(edition.publish_at, edition.id.to_s)
    end

    puts "#{editions_scheduled_for_publishing_count} editions scheduled for publishing were re-queued"
  end
end
