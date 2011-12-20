class LocalTransactionEdition < WholeEdition
  include Expectant

  referenced_in :lgsl,      class_name: "LocalTransactionsSource::Lgsl"

  field :lgsl_code,         type: String
  field :introduction,      type: String
  field :more_information,  type: String
  validates_presence_of :lgsl_code
 
  @fields_to_clone = [:introduction, :more_information, :minutes_to_complete, :expectation_ids]

  validates_presence_of :lgsl, :on => :create

  set_callback :validation, :before do |local_transaction|
    unless local_transaction.persisted? or lgsl_code.blank?
      local_transaction.lgsl = LocalTransactionsSource.find_current_lgsl(local_transaction.lgsl_code)
    end
  end

  def verify_snac(snac)
    lgsl.authorities.where(snac: snac).any?
  end
end
