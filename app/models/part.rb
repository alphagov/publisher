require_dependency "safe_html"

class Part
  include Mongoid::Document

  embedded_in :guide_edition
  embedded_in :programme_edition

  scope :in_order, -> { order_by(order: :asc) }

  field :order,      type: Integer
  field :title,      type: String
  field :body,       type: String
  field :slug,       type: String
  field :created_at, type: DateTime, default: -> { Time.zone.now }

  GOVSPEAK_FIELDS = [:body].freeze

  validate :validate_title_is_present, :validate_slug_is_present
  validates :slug, exclusion: { in: %w[video], message: "Can not be video" }
  validates :slug, format: { with: /\A[a-z0-9-]+\Z/i, message: "Slug can only consist of lower case characters, numbers and hyphens" }
  validates_with SafeHtml
  validates_with LinkValidator

private

  def validate_title_is_present
    errors.add(:title, "Enter a title for Part #{guide_edition.parts.find_index(self) + 1}") if title.blank?
  end

  def validate_slug_is_present
    errors.add(:slug, "Enter a slug for Part #{guide_edition.parts.find_index(self) + 1}") if slug.blank?
  end
end
