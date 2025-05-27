require "devolved_administration_availability"
class ScotlandAvailability < DevolvedAdministrationAvailability
  belongs_to :local_transaction_edition, class_name: "LocalTransactionEdition", inverse_of: :scotland_availability, optional: false
end
