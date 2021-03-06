require "local_service"
require "edition"

class LocalTransactionEdition < Edition
  field :lgsl_code, type: Integer
  field :lgil_override, type: Integer
  field :lgil_code, type: Integer
  field :introduction, type: String
  field :more_information, type: String
  field :need_to_know, type: String

  embeds_one :scotland_availability, class_name: DevolvedAdministrationAvailability, autobuild: true
  embeds_one :wales_availability, class_name: DevolvedAdministrationAvailability, autobuild: true
  embeds_one :northern_ireland_availability, class_name: DevolvedAdministrationAvailability, autobuild: true

  accepts_nested_attributes_for :scotland_availability
  accepts_nested_attributes_for :wales_availability
  accepts_nested_attributes_for :northern_ireland_availability

  GOVSPEAK_FIELDS = %i[introduction more_information need_to_know].freeze

  validate :valid_lgsl_code
  validates :lgil_code, numericality: { only_integer: true, message: "can only be whole number between 0 and 999." }

  def valid_lgsl_code
    unless service
      errors.add(:lgsl_code, "#{lgsl_code} not recognised")
    end
  end

  def format_name
    "Local transaction"
  end

  def search_format
    "transaction"
  end

  def service
    LocalService.find_by_lgsl_code(lgsl_code)
  end

  def whole_body
    introduction
  end

  def build_clone(target_class = nil)
    new_edition = super
    if new_edition.is_a?(LocalTransactionEdition)
      new_edition.scotland_availability = scotland_availability.clone
      new_edition.wales_availability = wales_availability.clone
      new_edition.northern_ireland_availability = northern_ireland_availability.clone
    end
    new_edition
  end
end
