require_dependency "safe_html"

class Part
  include Mongoid::Document

  embedded_in :guide_edition
  embedded_in :programme_edition

  scope :in_order, lambda { order_by(order: :asc) }

  field :order,      type: Integer
  field :title,      type: String
  field :body,       type: String
  field :slug,       type: String
  field :created_at, type: DateTime, default: lambda { Time.zone.now }

  GOVSPEAK_FIELDS = [:body].freeze

  validates_presence_of :title
  validates_presence_of :slug
  validates_exclusion_of :slug, in: ["video"], message: "Can not be video"
  validates_format_of :slug, with: /\A[a-z0-9\-]+\Z/i
  validates_with SafeHtml
  validates_with LinkValidator
end
