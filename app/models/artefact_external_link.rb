class ArtefactExternalLink
  # include Mongoid::Document

  strip_attributes only: :url

  field "title", type: String
  field "url", type: String

  has_many :artefact

  validates :title, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
end
