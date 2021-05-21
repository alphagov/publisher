class DevolvedAdministrationAvailability
  include Mongoid::Document

  embedded_in :local_transaction_edition
  field :type, type: String, default: "local_authority_service"
  field :alternative_url, type: String
end
