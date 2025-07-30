require_dependency "safe_html"

class Part < ApplicationRecord
  belongs_to :guide_edition, optional: true
  belongs_to :programme_edition, optional: true

  scope :in_order, -> { order(:order) }

  GOVSPEAK_FIELDS = [:body].freeze

  validate :validate_title_is_present
  validate :validate_slug_is_present
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
