class ArtefactExternalLink < ApplicationRecord
  strip_attributes only: :url

  belongs_to :artefact

  validates :title, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
end
