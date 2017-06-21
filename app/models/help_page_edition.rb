require "edition"

class HelpPageEdition < Edition
  field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze
  validates_with SafeHtml

  def whole_body
    self.body
  end
end
