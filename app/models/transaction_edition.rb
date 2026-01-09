require "edition"

class TransactionEdition < ApplicationRecord
  include Editionable

  strip_attributes only: :link

  GOVSPEAK_FIELDS = %i[introduction more_information alternate_methods need_to_know].freeze

  validates :start_button_text, presence: true

  def indexable_content
    "#{Govspeak::Document.new(introduction).to_text} #{Govspeak::Document.new(more_information).to_text}".strip
  end

  def whole_body
    [link, introduction, more_information, alternate_methods].join("\n\n")
  end

  def slug_prefix
    ""
  end
end
