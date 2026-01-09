class PlaceEdition < ApplicationRecord
  include Editionable

  GOVSPEAK_FIELDS = %i[introduction more_information need_to_know].freeze

  def whole_body
    introduction
  end

  def slug_prefix
    ""
  end
end
