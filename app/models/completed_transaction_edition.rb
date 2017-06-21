require "edition"

class CompletedTransactionEdition < Edition
  include PresentationToggles

  field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    self.body
  end
end
