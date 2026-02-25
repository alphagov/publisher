require_dependency "safe_html"

class Part < ApplicationRecord
  belongs_to :guide_edition, optional: true
  belongs_to :programme_edition, optional: true

  scope :in_order, -> { order(:order) }

  GOVSPEAK_FIELDS = [:body].freeze

  validates :title, presence: { message: ->(obj, _) { "Enter a title#{obj.send(:validation_message_chapter_number)}" } }
  validates :slug, presence: { message: ->(obj, _) { "Enter a slug#{obj.send(:validation_message_chapter_number)}" } }
  validates :slug, exclusion: { in: %w[video], message: ->(obj, _) { "Slug#{obj.send(:validation_message_chapter_number)} can not be 'video'" } }
  validates :slug, format: { with: /\A[a-z0-9-]+\Z/i, message: ->(obj, _) { "Slug#{obj.send(:validation_message_chapter_number)} can only consist of lower case characters, numbers and hyphens" } }, allow_blank: true
  validates_with SafeHtml
  validates_with LinkValidator

private

  def validation_message_chapter_number
    return unless persisted?

    " for Chapter #{guide_edition.parts.in_order.find_index(self) + 1}"
  end
end
