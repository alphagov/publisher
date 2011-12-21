class Place < Publication
  embeds_many :editions, :class_name => 'PlaceEdition', :inverse_of => :place

  def self.edition_class
    PlaceEdition
  end

end
