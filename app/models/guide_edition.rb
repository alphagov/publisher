class GuideEdition < Edition
  embedded_in :guide
  embeds_many :parts
  
  accepts_nested_attributes_for :parts, :allow_destroy => true, :reject_if => :all_blank

  @fields_to_clone = []

  def build_clone
    new_edition = super
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end
  
  def order_parts
    ordered_parts = parts.sort_by(&:order)
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end
  
  def container
    self.guide
  end
  
end