class LocalTransactionsSource::Authority
  include Mongoid::Document

  embeds_many :lgils, class_name: "LocalTransactionsSource::Lgil"
  embedded_in :lgsl,  class_name: "LocalTransactionsSource::Lgsl"

  field :snac, type: String
  field :name, type: String
  field :url,  type: String
end
