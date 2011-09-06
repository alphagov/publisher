class TransactionEdition < Edition
  embedded_in :transaction

  include Expectant

  field :introduction,      :type => String
  field :will_continue_on,  :type => String
  field :link,              :type => String
  field :more_information,  :type => String

  @fields_to_clone = [:introduction, :will_continue_on, :link, :more_information, :minutes_to_complete, :uses_government_gateway, :expectation_ids]

  def container
    self.transaction
  end
end
