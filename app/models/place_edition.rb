class PlaceEdition < WholeEdition
  include Expectant

  field :introduction,      :type => String
  field :more_information,  :type => String
  field :place_type,        :type => String

  @fields_to_clone = [:introduction, :more_information, :place_type, :expectation_ids]
end
