class ScheduledPublisher
  include Sidekiq::Worker

  # 5 retries over 10 mins
  sidekiq_options :retry => 5
  sidekiq_retry_in do |count|
    # 16s, 31s, 96s, 271s, 640s
    count ** 4 + 15
  end

  # NOTE on ids: edition and actor id are enqueued
  # as String or else marshalling converts it to a hash
  def self.cancel_scheduled_publishing(cancel_edition_id)
    Sidekiq::ScheduledSet.new.select do |scheduled_job|
      scheduled_job.args.first == cancel_edition_id
    end.map(&:delete)
  end

  def perform(edition_id)
    edition = Edition.find(edition_id)
    edition.publish_anonymously
    update_stats if edition.published?
  end

  private
    def update_stats
      require 'statsd'

      statsd.decrement("publisher.edition.scheduled_for_publishing")
      statsd.increment("publisher.edition.published")
    end

    def statsd
      @statsd ||= Statsd.new(::STATSD_HOST)
    end
end
