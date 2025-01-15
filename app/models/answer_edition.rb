# require "edition"

class AnswerEdition < ApplicationRecord
  include Workflow
  include RecordableActions
  include Common
  has_many :actions, as: :actionable
  # field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end
end
