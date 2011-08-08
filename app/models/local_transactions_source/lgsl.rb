class LocalTransactionsSource::Lgsl
  include Mongoid::Document

  belongs_to  :local_transactions_source
  embeds_many :authorities, class_name: "LocalTransactionsSource::Authority"

  field :code, type: String
end
