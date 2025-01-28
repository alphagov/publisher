require "edition"

class HelpPageEdition < EditionTemp
  field :body, type: String

  GOVSPEAK_FIELDS = [:body].freeze
  validates_with SafeHtml

  def whole_body
    body
  end
end
