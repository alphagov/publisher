require "edition"
require "attachable"

class VideoEdition < Edition
  include Attachable

  field :video_url,     type: String
  field :video_summary, type: String
  field :body,          type: String

  GOVSPEAK_FIELDS = [:body].freeze

  attaches :caption_file

  def has_video?
    video_url.present?
  end

  def whole_body
    [video_summary, video_url, body].join("\n\n")
  end
end
