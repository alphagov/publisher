class TransactionEdition < Edition
  embedded_in :transaction
  
  field :will_continue_on,  :type => String
  field :link,              :type => String
  field :more_information,  :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }

  def build_clone
    self.transaction.build_edition(self.title)
  end
  
  def calculate_statuses
    self.transaction.calculate_statuses
  end
  
  def publish(edition,notes)
    self.teansaction.publish(edition,notes)
  end
  
  def container
    return self.transaction
  end  
end
