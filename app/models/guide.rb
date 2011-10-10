class Guide < Publication
  embeds_many :editions, :class_name => 'GuideEdition', :inverse_of => :guide

  def self.edition_class
    GuideEdition
  end
  
  def has_video?
    latest_edition.video_url.present?
  end
  

end
