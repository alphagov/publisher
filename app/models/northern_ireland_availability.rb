require "devolved_administration_availability"

class NorthernIrelandAvailability < DevolvedAdministrationAvailability
  belongs_to :local_transaction_edition, class_name: "LocalTransactionEdition", inverse_of: :northern_ireland_availability, optional: false
end
