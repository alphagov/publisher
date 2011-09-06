class Transaction < Publication
  embeds_many :editions, :class_name => 'TransactionEdition', :inverse_of => :transaction

  def self.edition_class
    TransactionEdition
  end

end
