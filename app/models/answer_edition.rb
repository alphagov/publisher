class AnswerEdition < Edition
  embedded_in :answer

  field :body, :type => String

  @fields_to_clone = [:body]

  def container
    self.answer
  end

end
