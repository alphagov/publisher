class Guide < Publication
  embeds_many :editions, :class_name => 'GuideEdition', :inverse_of => :guide

  def self.edition_class
    GuideEdition
  end

end
