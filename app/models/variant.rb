require_dependency "safe_html"

class Variant
  include Mongoid::Document

  strip_attributes only: :link

  embedded_in :transaction_edition

  scope :in_order, lambda { order_by(order: :asc) }

  field :order,             type: Integer
  field :title,             type: String
  field :slug,              type: String
  field :introduction,      type: String
  field :link,              type: String
  field :more_information,  type: String
  field :alternate_methods, type: String
  field :created_at,        type: DateTime, default: lambda { Time.zone.now }

  GOVSPEAK_FIELDS = %i[introduction more_information alternate_methods].freeze

  validates_presence_of :title
  validates_presence_of :slug
  validates_exclusion_of :slug, in: %w[video], message: "Can not be video"
  validates_format_of :slug, with: /\A[a-z0-9\-]+\Z/i
  validates_with SafeHtml
  validates_with LinkValidator
end
