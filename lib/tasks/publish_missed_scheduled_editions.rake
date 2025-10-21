namespace :editions do
  desc "Publish editions missed in scheduled publishing"
  task publish_missed_scheduled_editions: :environment do
    scheduled_editions = Edition.scheduled_for_publishing.where("publish_at < ?", Time.zone.now)

    scheduled_editions.each do |edition|
      ScheduledPublisher.new.perform(edition.id.to_s)
      Rails.logger.warn "Published missed scheduled edition with ID: #{edition.id} "
    end
  end
end
