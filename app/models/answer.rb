class Answer < Publication
  embeds_many :editions, :class_name => 'AnswerEdition', :inverse_of => :answer

  def self.edition_class
    AnswerEdition
  end

  def indexable_content
    if latest_edition
      [ super,
        govspeak_to_text(latest_edition.body)
      ].join(" ").strip
    else
      super
    end
  end
end
