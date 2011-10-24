class GuideEdition < Edition
  embedded_in :guide
  embeds_many :parts
  
  accepts_nested_attributes_for :parts, :allow_destroy => true,
    :reject_if => proc { |attrs| attrs['title'].blank? and attrs['body'].blank? }
  
  field :video_url,	:type => String
  field :video_summary, :type => String

  @fields_to_clone = [:video_url, :video_summary]

  def build_clone
    new_edition = super
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end
  
  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end
  
  def container
    self.guide
  end
  
end