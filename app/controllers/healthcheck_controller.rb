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
    queue_size = Sidekiq::Stats.new.scheduled_size

    if scheduled_editions == queue_size
      {"status" => "ok"}
    else
      {
        "status" => "warning",
        "message" => "#{scheduled_editions} scheduled edition(s); #{queue_size} item(s) queued"
      }
    end
  rescue Mongo::MongoRubyError, Mongo::MongoDBError, Redis::CannotConnectError
    {
      "status" => "critical",
      "message" => "Unable to check scheduled counts"
    }
  end
end
