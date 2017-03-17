class DowntimeScheduler
  include Sidekiq::Worker

  def self.schedule_publish_and_expiry(downtime)
    return if downtime.nil?

    # publish the downtime message at midnight the night before
    display_date = downtime.display_start_time
    perform_now_or_later(downtime.id.to_s, display_date)

    # remove the downtime after it expires
    # assumes that the expiry will always be in the future
    expiry_date = downtime.end_time + 15.seconds
    perform_at(expiry_date, downtime.id.to_s)
  end

  def perform(downtime_id)
    downtime = Downtime.where(id: downtime_id).first
    return if downtime.nil?

    artefact = downtime.artefact

    if downtime.end_time.to_time <= Time.zone.now
      downtime.destroy
    end

    PublishingApiWorkflowBypassPublisher.call(artefact)
  end

  def self.perform_now_or_later(downtime_id, datetime)
    if datetime.past?
      perform_async(downtime_id)
    else
      perform_at(datetime.to_time.to_i, downtime_id)
    end
  end
end
