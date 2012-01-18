class Transaction < Publication
  embeds_many :editions, :class_name => 'TransactionEdition', :inverse_of => :transaction

  def self.edition_class
    TransactionEdition
  end

  def indexable_content
    if latest_edition
      [ super,
        govspeak_to_text(latest_edition.introduction),
        govspeak_to_text(latest_edition.more_information)
      ].join(" ").strip
    else
      super
    end
  end

end
