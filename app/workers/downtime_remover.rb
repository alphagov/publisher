class DowntimeRemover
  include Sidekiq::Worker

  def self.destroy_immediately(downtime)
    return if downtime.nil?

    artefact_id = downtime.artefact.id.to_s
    downtime.destroy
    perform_async(artefact_id)
  end

  def perform(artefact_id)
    artefact = Artefact.find_by(id: artefact_id)
    PublishingApiWorkflowBypassPublisher.call(artefact)
  end
end
