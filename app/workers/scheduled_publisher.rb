class ScheduledPublisher
  include Sidekiq::Worker

  # 5 retries over 10 mins
  sidekiq_options retry: 5
  sidekiq_retry_in do |count|
    # 16s, 31s, 96s, 271s, 640s
    count**4 + 15
  end

  def self.enqueue(edition)
    perform_at(edition.publish_at, edition.id.to_s)
  end

  # NOTE on ids: edition and actor id are enqueued
  # as String or else marshalling converts it to a hash
  def self.cancel_scheduled_publishing(cancel_edition_id)
    queued_jobs.select { |scheduled_job|
      scheduled_job.args.first == cancel_edition_id
    }.map(&:delete)
  end

  def self.queue_size
    queued_jobs.size
  end

  # used by the editions:requeue_scheduled_for_publishing rake task
  def self.dequeue_all
    queued_jobs.map(&:delete)
  end

  def perform(edition_id)
    edition = Edition.find(edition_id)
    edition.publish_anonymously!

    PublishService.call(edition)

    report_state_counts
  end

private

  def report_state_counts
    Publisher::Application.edition_state_count_reporter.report
  end

  def self.queued_jobs
    Sidekiq::ScheduledSet.new.select { |job| job['class'] == self.name }
  end
  class << self
    private :queued_jobs
  end
end
