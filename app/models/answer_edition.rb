class AnswerEdition < Edition
  embedded_in :answer
  
  field :title, :type => String
  field :body, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  
  def build_clone
     new_edition = self.answer.build_edition(self.title)
     new_edition
  end
  
  def calculate_statuses
    self.answer.calculate_statuses
  end
  
   def publish(edition,notes)
     self.answer.publish(edition,notes)
   end
end