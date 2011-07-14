class Guide < Publication
  embeds_many :editions, :class_name => 'GuideEdition', :inverse_of => :publication
  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }
  
  def build_edition(title)
    version_number = self.editions.length + 1
    edition = GuideEdition.new(:title=> title, :version_number=>version_number)
    self.editions << edition
    calculate_statuses
    edition
  end
  
  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << GuideEdition.new
    end
    calculate_statuses
  end
  
end




