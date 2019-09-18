class ArtefactExternalLink
  include Mongoid::Document

  strip_attributes only: :url

  field "title", type: String
  field "url", type: String

  embedded_in :artefact

  validates_presence_of :title
  validates :url, presence: true, format: { with: URI::regexp(%w{http https}) }
end
