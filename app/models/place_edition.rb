class PlaceEdition < Edition
  include Expectant

  embedded_in :place

  field :introduction,      :type => String
  field :more_information,  :type => String
  field :place_type,        :type => String

  @fields_to_clone = [:introduction, :more_information, :place_type, :expectation_ids]

  def container
    self.place
  end

  def whole_body
    self.introduction
  end
end
