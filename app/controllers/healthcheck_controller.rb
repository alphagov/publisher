class HealthcheckController < ApplicationController
  skip_before_action :authenticate_user!

  def scheduled_publishing
    render json: Healthcheck::ScheduledPublishing.new.to_hash
  end
end
