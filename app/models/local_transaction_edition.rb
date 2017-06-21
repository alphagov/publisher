require "local_service"
require "edition"

class LocalTransactionEdition < Edition
  field :lgsl_code, type: Integer
  field :lgil_override, type: Integer
  field :lgil_code, type: Integer
  field :introduction, type: String
  field :more_information, type: String
  field :need_to_know, type: String

  GOVSPEAK_FIELDS = [:introduction, :more_information, :need_to_know].freeze

  validate :valid_lgsl_code
  validates :lgil_code, numericality: { only_integer: true, message: "can only be whole number between 0 and 999." }

  def valid_lgsl_code
    if ! self.service
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
    self.introduction
  end
end
