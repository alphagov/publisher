class PlaceEdition < Edition
  embedded_in :place

  field :introduction,      :type => String
  field :more_information,  :type => String
  field :place_type,        :type => String

  @fields_to_clone = [:introduction, :will_continue_on, :link, :more_information, :place_type]

  def container
    self.place
  end
end
