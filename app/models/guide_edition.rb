require "edition"
require "parted"

class GuideEdition < Edition
  include Parted

  strip_attributes only: :video_url

  field :video_url, type: String
  field :video_summary, type: String
  field :hide_chapter_navigation, type: Boolean

  GOVSPEAK_FIELDS = [].freeze

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    super && parts.any? && parts.first.slug.present?
  end

  def return_self_and_nested_objects_with_errors
    top_level_errors = errors.present? ? [self] : []

    all_objects_with_errors = top_level_errors + parts.select { |part| part.errors.present? }

    all_objects_with_errors.each do |object|
      object.errors.errors.reject! do |error|
        error.type == :invalid || error.attribute == :parts
      end
    end
  end
end
