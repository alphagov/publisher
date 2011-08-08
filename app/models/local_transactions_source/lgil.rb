class LocalTransactionsSource::Lgil
  include Mongoid::Document

  field :code, type: String
  field :url, type: String

  embedded_in :authority, class_name: "LocalTransactionsSource::Authority"
end
