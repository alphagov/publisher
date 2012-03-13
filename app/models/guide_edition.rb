class GuideEdition < WholeEdition
  #include Parted
  include PartedEdition

  #TODO: Merge Conflict (do we need this?)
  #accepts_nested_attributes_for :parts, :allow_destroy => true,
  #  :reject_if => proc { |attrs| attrs['title'].blank? and attrs['body'].blank? }

  field :video_url,  :type => String
  field :video_summary, :type => String

  @fields_to_clone = [:video_url, :video_summary]

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    parts.any? and parts.first.slug.present?
  end

end
