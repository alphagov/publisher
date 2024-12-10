require "edition"

class AnswerEdition < ApplicationRecord
  include Editionable
  # field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end
end
