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

  def update_from_edition(edition)
    update_attributes(
      state: state_from_edition(edition),
      description: edition.overview,
      public_timestamp: edition.public_updated_at,
      paths: edition.paths,
      prefixes: edition.prefixes
    )
  end

private

  def state_from_edition(edition)
    case edition.state
    when 'published' then 'live'
    when 'archived' then 'archived'
    else 'draft'
    end
  end

  def discard_publishing_api_draft
    Services.publishing_api.discard_draft(self.content_id)
  end
end
