require "edition"
require "parted"

class GuideEdition < Edition
  include Parted

  field :video_url,     type: String
  field :video_summary, type: String

  GOVSPEAK_FIELDS = [].freeze

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    super && parts.any? && parts.first.slug.present?
  end
end
