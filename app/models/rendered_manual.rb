require "prerendered_entity"

class RenderedManual
  include Mongoid::Document
  include Mongoid::Timestamps
  extend PrerenderedEntity

  field :manual_id, type: String
  field :slug, type: String
  field :title, type: String
  field :summary, type: String
  field :section_groups, type: Array

  index({ slug: 1 }, unique: true)

  validates_uniqueness_of :slug
end
