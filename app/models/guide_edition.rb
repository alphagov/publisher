class GuideEdition < Edition
  embedded_in :guide
  embeds_many :parts
  
  accepts_nested_attributes_for :parts, :allow_destroy => true, :reject_if => :all_blank

   def build_clone
     new_edition = self.guide.build_edition(self.title)
     new_edition.parts = self.parts.map {|p| p.dup }
     new_edition
   end

   def order_parts
     parts.each_with_index do |obj, i|
       obj.order = i + 1
     end
   end
  
   def calculate_statuses
     self.guide.calculate_statuses
   end
  
   def publish(edition,notes)
     self.guide.publish(edition,notes)
   end
  
end