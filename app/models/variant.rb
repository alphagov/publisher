require_dependency "safe_html"

class Variant < ApplicationRecord
  # include Mongoid::Document

  strip_attributes only: :link

  has_many :transaction_edition

  scope :in_order, -> { order_by(order: :asc) }

  # field :order,             type: Integer
  # field :title,             type: String
  # field :slug,              type: String
  # field :introduction,      type: String
  # field :link,              type: String
  # field :more_information,  type: String
  # field :alternate_methods, type: String
  # field :created_at,        type: DateTime, default: -> { Time.zone.now }

  GOVSPEAK_FIELDS = %i[introduction more_information alternate_methods].freeze

  validates :title, presence: true
  validates :slug, presence: true
  validates :slug, exclusion: { in: %w[video], message: "Can not be video" }
  validates :slug, format: { with: /\A[a-z0-9-]+\Z/i, message: "Slug can only consist of lower case characters, numbers and hyphens" }
  validates_with SafeHtml
  validates_with LinkValidator
end
