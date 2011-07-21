class Answer < Publication
  embeds_many :editions, :class_name => 'AnswerEdition', :inverse_of => :answer
  
  def self.edition_class
     AnswerEdition
   end
end