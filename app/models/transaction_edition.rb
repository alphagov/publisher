require "edition"
require "varianted"

class TransactionEdition < Edition
  include Varianted

  strip_attributes only: :link

  field :introduction, type: String
  field :will_continue_on, type: String
  field :link, type: String
  field :more_information, type: String
  field :need_to_know, type: String
  field :department_analytics_profile, type: String
  field :alternate_methods, type: String
  field :start_button_text, type: String, default: "Start now"

  GOVSPEAK_FIELDS = %i[introduction more_information alternate_methods need_to_know].freeze

  validates :department_analytics_profile, format: { with: /UA-\d+-\d+/i, allow_blank: true, message: "Invalid format for service analytics profile: must be in format UA-xxxxx-x where xs are digits" }
  validates :start_button_text, presence: true
  validates_with SafeHtml

  def indexable_content
    "#{super} #{Govspeak::Document.new(introduction).to_text} #{Govspeak::Document.new(more_information).to_text}".strip
  end

  def whole_body
    [link, introduction, more_information, alternate_methods].join("\n\n")
  end
end
