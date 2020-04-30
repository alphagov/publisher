require "edition"

class AnswerEdition < Edition
  field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end
end
