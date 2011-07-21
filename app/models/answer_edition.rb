class AnswerEdition < Edition
  embedded_in :answer
  
  field :body, :type => String
   
  def container
    self.answer
  end
end