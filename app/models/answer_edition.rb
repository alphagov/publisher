require "edition"

class AnswerEdition < Edition
  # include Editionable
  # field :body, type: String
  store_accessor :edition_specific_content, :body

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end
end
