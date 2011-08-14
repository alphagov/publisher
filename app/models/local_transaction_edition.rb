class LocalTransactionEdition < Edition
  embedded_in :local_transaction

  field :introduction,      type: String
  # field :will_continue_on,  type: String
  # field :link,              type: String
  field :more_information,  type: String
  field :expectation_ids,   type: Array, default: []

  @fields_to_clone = [:introduction, :more_information, :lgsl, :expectation_ids]

  def admin_list_title
    "#{title} (LGSL #{local_transaction.lgsl_code}) [#{local_transaction.lgsl.authorities.count}]"
  end

  def expectations
    Expectation.criteria.in(_id: self.expectation_ids)
  end

  def self.expectation_choices
    Hash[Expectation.all.map {|e| [e.text, e._id.to_s] }]
  end

  def container
    self.local_transaction
  end
end
