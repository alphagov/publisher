class PublishingApiWorkflowBypassPublisher
  def initialize(artefact)
    @artefact = artefact
  end

  def self.call(artefact)
    new(artefact).call
  end

  def call
    return if artefact.nil?

    discard_draft if has_local_draft?
    republish_currently_live_edition if has_live_edition?
    put_draft_content if has_local_draft?
  end

private

  attr_reader :artefact

  def has_local_draft?
    draft_edition.present?
  end

  def has_live_edition?
    live_edition.present?
  end

  def discard_draft
    Services.publishing_api.discard_draft(artefact.content_id)
  end

  def republish_currently_live_edition
    PublishingAPIUpdater.new.perform(live_edition.id)
    PublishService.call(edition, 'republish')
  end

  def put_draft_content
    PublishingAPIUpdater.new.perform(draft_edition.id)
  end

  def live_edition
    Edition
      .where(panopticon_id: artefact.id)
      .where(state: 'published')
      .first
  end

  def draft_edition
    Edition
      .where(panopticon_id: artefact.id)
      .where(state: { "$nin" => %w(published, archived) })
      .first
  end
end
