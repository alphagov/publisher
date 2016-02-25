class HealthcheckController < ActionController::Base
  # Not inheriting from ApplicationController here so we don't need OAuth
  # authentication to access the health check

  def check
    health_status = {"checks" => {}}
    health_status["checks"]["schedule_queue"] = schedule_queue_result
    health_status["status"] = health_status["checks"]["schedule_queue"]["status"]
    render :json => health_status
  end

private

  def schedule_queue_result
    scheduled_editions = Edition.scheduled_for_publishing.count
    queue_size = ScheduledPublisher.queue_size

    status = (scheduled_editions == queue_size) ? "ok" : "warning"

    {
      "status" => status,
      "message" => "#{scheduled_editions} scheduled edition(s); #{queue_size} item(s) queued"
    }
  rescue Mongo::Error, Redis::CannotConnectError
    {
      "status" => "critical",
      "message" => "Unable to check scheduled counts"
    }
  end
end
