namespace :editions do
  desc "Re-queue editions scheduled for publishing"
  task :requeue_scheduled_for_publishing => :environment do
    criteria = Edition.scheduled_for_publishing
    editions_scheduled_for_publishing_count = criteria.count

    puts " clearing scheduled publishing queue"
    ScheduledPublisher.dequeue_all

    criteria.each do |edition|
      puts " scheduling publishing of: #{edition.slug}"
      ScheduledPublisher.enqueue(edition)
    end

    puts "#{editions_scheduled_for_publishing_count} editions scheduled for publishing were re-queued"
  end
end
