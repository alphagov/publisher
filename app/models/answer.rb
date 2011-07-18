class Answer < Publication
  embeds_many :editions, :class_name => 'AnswerEdition', :inverse_of => :answer
  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }

  field :body,        :type => String
  
  def build_edition(title)
    version_number = self.editions.length + 1
    edition = AnswerEdition.new(:title=> title, :version_number=>version_number)
    self.editions << edition
    calculate_statuses
    edition
  end
  
  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << AnswerEdition.new(:title => self.name)
    end
    calculate_statuses
  end
  
  
  
end