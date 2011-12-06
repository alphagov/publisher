class Answer < Publication
  embeds_many :editions, :class_name => 'AnswerEdition', :inverse_of => :answer

  def self.edition_class
    AnswerEdition
  end

  def indexable_content
    content = super
    return content unless latest_edition
    "#{content} #{latest_edition.body}".strip
  end
end
