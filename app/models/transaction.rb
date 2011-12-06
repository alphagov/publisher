class Transaction < Publication
  embeds_many :editions, :class_name => 'TransactionEdition', :inverse_of => :transaction

  def self.edition_class
    TransactionEdition
  end

  def indexable_content
    content = super
    return content unless latest_edition
    "#{content} #{latest_edition.introduction} #{latest_edition.more_information}".strip
  end

end
