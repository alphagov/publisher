require "artefact"

class Artefact
  before_destroy :discard_publishing_api_draft

  def latest_edition_id
    Edition
      .where(panopticon_id: id)
      .order(version_number: :desc)
      .first
      .id
      .to_s
  end

private

  def discard_publishing_api_draft
    Services.publishing_api.discard_draft(self.content_id)
  end
end
