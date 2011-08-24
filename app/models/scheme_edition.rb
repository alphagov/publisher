class SchemeEdition < Edition
  embedded_in :scheme
  embeds_many :parts
  
  accepts_nested_attributes_for :parts, :allow_destroy => true, :reject_if => :all_blank

  @fields_to_clone = []

  def build_clone
    new_edition = super
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end
  
  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end
  
  def container
    self.scheme
  end
  
end
