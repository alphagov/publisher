class ArtefactExternalLink
  include Mongoid::Document

  field "title", type: String
  field "url", type: String

  embedded_in :artefact

  validates_presence_of :title
  validates :url, presence: true, format: { with: URI::regexp(%w{http https}) }
end
