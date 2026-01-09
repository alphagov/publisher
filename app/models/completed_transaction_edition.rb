class CompletedTransactionEdition < ApplicationRecord
  include PresentationToggles
  include Editionable

  GOVSPEAK_FIELDS = [:body].freeze

  def whole_body
    body
  end

  def slug_prefix
    "done/"
  end
end
