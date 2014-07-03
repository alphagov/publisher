class HealthcheckController < ActionController::Base
  # Not inheriting from ApplicationController here so we don't need OAuth
  # authentication to access the health check

  respond_to :json

  def check
    health_status = {"status" => "ok"}
    respond_with health_status
  end
end
