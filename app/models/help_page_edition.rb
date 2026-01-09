class HelpPageEdition < ApplicationRecord
  include Editionable

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end

  def slug_prefix
    "help/"
  end
end
