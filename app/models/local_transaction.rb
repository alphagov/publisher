class LocalTransaction < Publication
  embeds_many   :editions,  class_name: 'LocalTransactionEdition', inverse_of: :local_transaction
  referenced_in :lgsl,      class_name: "LocalTransactionsSource::Lgsl"

  field         :lgsl_code, type: String

  validates_presence_of :lgsl_code
  validates_presence_of :lgsl, :on => :create

  set_callback :validation, :before do |local_transaction|
    unless local_transaction.persisted?
      local_transaction.lgsl = LocalTransactionsSource.find_current_lgsl(local_transaction.lgsl_code)
    end
  end

  def self.edition_class
    LocalTransactionEdition
  end
end
