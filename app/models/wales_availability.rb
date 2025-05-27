require "devolved_administration_availability"

class WalesAvailability < DevolvedAdministrationAvailability
  belongs_to :local_transaction_edition, class_name: "LocalTransactionEdition", inverse_of: :wales_availability, optional: false
end
