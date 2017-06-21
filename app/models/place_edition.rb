require "edition"

class PlaceEdition < Edition
  field :introduction, type: String
  field :more_information, type: String
  field :need_to_know, type: String
  field :place_type, type: String

  GOVSPEAK_FIELDS = [:introduction, :more_information, :need_to_know].freeze

  def whole_body
    self.introduction
  end
end
