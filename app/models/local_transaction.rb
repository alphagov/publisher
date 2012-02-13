class LocalTransaction < Publication
  embeds_many   :editions,  class_name: 'LocalTransactionEdition', inverse_of: :local_transaction

  field         :lgsl_code, type: Integer

  validates_presence_of :lgsl_code
  validate      :valid_lgsl_code

  def self.edition_class
    LocalTransactionEdition
  end

  def search_format
    "transaction"
  end
  
  def service
    LocalService.find_by_lgsl_code(lgsl_code)
  end

  def service_provided_by?(snac)
    authority = LocalAuthority.find_by_snac(snac)
    authority && authority.provides_service?(lgsl_code)
  end
  
  def valid_lgsl_code
    if ! LocalService.find_by_lgsl_code(lgsl_code)
      errors.add(:lgsl_code, "Invalid LGSL Code: '#{lgsl_code}'")
    end
  end
end
