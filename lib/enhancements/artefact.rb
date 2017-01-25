require "artefact"

class Artefact
  before_destroy :discard_publishing_api_draft

  def self.published_edition_ids_for_format(format)
    artefact_ids = Artefact.where(kind: format).pluck(:id).map(&:to_s)

    Edition
      .where(panopticon_id: { '$in' => artefact_ids })
      .where(state: 'published')
      .map(&:id)
      .map(&:to_s)
  end

  def latest_edition
    Edition
      .where(panopticon_id: id)
      .order(version_number: :desc)
      .first
  end

  def latest_edition_id
    edition = latest_edition
    edition.id.to_s if edition
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
