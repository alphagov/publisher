require "artefact"

class Artefact
  before_destroy :discard_publishing_api_draft

private

  def discard_publishing_api_draft
    Services.publishing_api.discard_draft(self.content_id)
  end
end
