class ExpiredDowntimeCleaner
  include Sidekiq::Worker

  def self.enqueue(downtime)
    dequeue_existing_jobs(downtime)
    perform_at(downtime.end_time + 15.seconds, downtime.id.to_s)
  end

  def self.dequeue_existing_jobs(downtime)
    Sidekiq::ScheduledSet.new.select do |job|
      job['class'] == self.name && job.args.first == downtime.id.to_s
    end.map(&:delete)
  end

  def perform(downtime_id)
    downtime = Downtime.where(_id: downtime_id).first
    return if downtime.nil? || downtime.end_time.future?

    downtime.destroy
  end
end
