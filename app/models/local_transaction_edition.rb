require "local_service"

class LocalTransactionEdition < ApplicationRecord
  include Editionable

  has_one :scotland_availability, inverse_of: :local_transaction_edition, class_name: "ScotlandAvailability", dependent: :destroy
  has_one :wales_availability, inverse_of: :local_transaction_edition, class_name: "WalesAvailability", dependent: :destroy
  has_one :northern_ireland_availability, inverse_of: :local_transaction_edition, class_name: "NorthernIrelandAvailability", dependent: :destroy

  accepts_nested_attributes_for :scotland_availability
  accepts_nested_attributes_for :wales_availability
  accepts_nested_attributes_for :northern_ireland_availability

  after_initialize :build_associations

  after_validation :merge_errors

  GOVSPEAK_FIELDS = %i[introduction more_information need_to_know before_text after_text].freeze

  validate :valid_lgsl_code, if: -> { lgsl_code.present? }
  validates :lgil_code, presence: { message: "Enter a LGIL code" }
  validates :lgsl_code, presence: { message: "Enter a LGSL code" }
  validates :lgil_code, numericality: { only_integer: true, message: "LGIL code can only be a whole number between 0 and 999" }, if: -> { lgil_code.present? }

  def valid_lgsl_code
    unless service
      errors.add(:lgsl_code, "LGSL code is not recognised")
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

  def slug_prefix
    ""
  end

  def copy_to(other)
    if other.is_a?(LocalTransactionEdition)
      other.scotland_availability = scotland_availability.clone
      other.scotland_availability.mongo_id = nil
      other.wales_availability = wales_availability.clone
      other.wales_availability.mongo_id = nil
      other.northern_ireland_availability = northern_ireland_availability.clone
      other.northern_ireland_availability.mongo_id = nil
    end
  end

private

  def merge_errors
    %i[scotland_availability wales_availability northern_ireland_availability].each do |availability|
      nested_errors = public_send(availability)&.errors
      next if nested_errors.nil?

      nested_errors.each do |error|
        errors.delete("#{availability}.#{error.attribute}")
        errors.add("#{availability}_attributes_#{error.attribute}", error.message)
      end
    end
  end

  def build_associations
    self.northern_ireland_availability ||= NorthernIrelandAvailability.new
    self.scotland_availability ||= ScotlandAvailability.new
    self.wales_availability ||= WalesAvailability.new
  end
end
