class ExpiredDowntimeCleaner
  include Sidekiq::Worker

  def self.enqueue(downtime)
    dequeue_existing_jobs(downtime)
    perform_at(downtime.end_time, downtime.id.to_s)
  end

  def self.dequeue_existing_jobs(downtime)
    Sidekiq::ScheduledSet.new.select do |job|
      job['class'] == self.name && job.args.first == downtime.id.to_s
    end.map(&:delete)
  end

  def perform(downtime_id)
    downtime = Downtime.find(downtime_id)
    return if downtime.end_time.future?

    downtime.destroy
  end
end
