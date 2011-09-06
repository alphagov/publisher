class LocalTransactionEdition < Edition
  include Expectant

  embedded_in :local_transaction

  field :introduction,      type: String
  field :more_information,  type: String

  @fields_to_clone = [:introduction, :more_information, :minutes_to_complete, :expectation_ids]

  def admin_list_title
    "#{title} (LGSL #{local_transaction.lgsl_code}) [#{local_transaction.lgsl.authorities.count}]"
  end

  def container
    self.local_transaction
  end
end
