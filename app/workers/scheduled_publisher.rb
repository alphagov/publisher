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
    state_count_reporter.report
  end

private

  def state_count_reporter
    StateCountReporter.new(
      Edition,
      Edition.state_names,
      Publisher::Application.statsd,
    )
  end
end
