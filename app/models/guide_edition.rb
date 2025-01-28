require "edition"
require "parted"

class GuideEdition < ApplicationRecord
  include Parted

  # strip_attributes only: :video_url

  # field :video_url, type: String
  # field :video_summary, type: String
  # field :hide_chapter_navigation, type: Boolean
  include Editionable

  GOVSPEAK_FIELDS = [].freeze

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    super && parts.any? && parts.first.slug.present?
  end
end
