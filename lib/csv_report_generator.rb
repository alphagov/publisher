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

  def presenters
    two_years_ago = 2.years.ago.at_beginning_of_day
    current_time = Time.zone.now

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

      ContentWorkflowPresenter.new(Edition.published.order(created_at: :desc)),

      RecentContentWorkflowPresenter.new(Edition.where(updated_at: two_years_ago..current_time)
                                         .or(Edition.where(created_at: two_years_ago..current_time)).order(created_at: :desc)),

      AllUrlsPresenter.new(
        Artefact.where(owning_app: "publisher").where.not(state: %w[archived]),
      ),
    ]
  end

  def redis
    Redis.new(REDIS_CONFIG)
  end
end
