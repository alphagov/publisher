class TransactionEdition < Edition
  embedded_in :transaction
  
  field :will_continue_on,  :type => String
  field :link,              :type => String
  field :more_information,  :type => String
  
  def container
    self.transaction
  end  
end
