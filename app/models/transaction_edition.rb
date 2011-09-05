class TransactionEdition < Edition
  embedded_in :transaction
  
  include Expectant
  
  field :introduction,      :type => String
  field :will_continue_on,  :type => String
  field :link,              :type => String
  field :more_information,  :type => String
  
  @fields_to_clone = [:introduction, :will_continue_on, :link, :more_information, :expectation_ids]
 
  validates_presence_of :will_continue_on
  validates_presence_of :introduction
  validates_presence_of :link # Should also be a valid URL
  validates_presence_of :more_information

  def container
    self.transaction
  end
end
