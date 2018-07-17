module Healthcheck
  class ScheduledPublishing
    def name
      :schedule_queue
    end

    def status
      queue_size_matches_edition_count? ? :ok : :warning
    end

    def details
      {
        queue_size: queue_size,
        edition_count: edition_count,
      }
    end

    def message
      "#{edition_count} scheduled edition(s); #{queue_size} item(s) queued"
    end

  private

    def queue_size_matches_edition_count?
      queue_size == edition_count
    end

    def queue_size
      @queue_size ||= ScheduledPublisher.queue_size
    end

    def edition_count
      @edition_count ||= Edition.scheduled_for_publishing.count
    end
  end
end
