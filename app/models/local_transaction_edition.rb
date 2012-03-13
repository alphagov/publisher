class LocalTransactionEdition < WholeEdition
  include Expectant

  referenced_in :lgsl,      class_name: "LocalTransactionsSource::Lgsl"

  field :lgsl_code,         type: String
  field :introduction,      type: String
  field :more_information,  type: String
 
  @fields_to_clone = [:introduction, :more_information, :minutes_to_complete, :expectation_ids]

  def whole_body
    self.introduction
  end

end
