require "parted"

class GuideEdition < ApplicationRecord
  include Editionable
  include Parted

  strip_attributes only: :video_url

  GOVSPEAK_FIELDS = [].freeze

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    super && parts.any? && parts.first.slug.present?
  end
end
