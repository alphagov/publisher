class Edition
  include Mongoid::Document
  
  embedded_in :guide
  
  embeds_many :parts
  embeds_many :actions
  
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :introduction, :type => String
  
  def build_clone
    new_edition = self.guide.build_edition(self.title,self.introduction)
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end
  
  def publish!(notes)
    self.guide.publish!(self,notes)
  end
  
end
