require "redis"
require "redis-lock"

class CsvReportGenerator
  def run!
    Redis.new.lock("publisher:report_generation_lock", life: 900) do
      presenters.each do |presenter|
        report = Report.new(presenter.report_name)

        Rails.logger.debug "Uploading #{report.filename} to S3"
        report.upload_to_s3(presenter.to_csv)
      end
    end
  rescue Redis::Lock::LockNotAcquired => e
    Rails.logger.debug("Failed to get lock for report generation (#{e.message}). Another process probably got there first.")
  end

  def editions_active_in_past_two_years
    Edition.where(
      "updated_at BETWEEN :start_time AND :end_time OR created_at BETWEEN :start_time AND :end_time",
      start_time: 2.years.ago.at_beginning_of_day,
      end_time: Time.zone.now,
    ).order(created_at: :desc).includes(:actions)
  end

  def presenters
    @presenters ||= [
      EditorialProgressPresenter.new(
        Edition.where.not(state: %w[archived]),
      ),

      EditionChurnPresenter.new(
        Edition.where.not(state: %w[archived]).order(:created_at),
      ),

      AllEditionChurnPresenter.new(
        Edition.all.order(:created_at),
      ),

      OrganisationContentPresenter.new(
        Artefact.where(owning_app: "publisher").where.not(state: %w[archived]),
      ),

      ContentWorkflowPresenter.new(
        Edition.published.order(created_at: :desc),
      ),

      AllContentWorkflowPresenter.new(editions_active_in_past_two_years),

      AllUrlsPresenter.new(
        Artefact.where(owning_app: "publisher").where.not(state: %w[archived]),
      ),
    ]
  end

  def redis
    Redis.new(REDIS_CONFIG)
  end
end
