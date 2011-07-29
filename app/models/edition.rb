class Edition
  include Mongoid::Document
  
  include Workflow
    
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  
  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []
  
  validate :not_editing_published_item
  
  def not_editing_published_item
  	errors.add(:base, "Published editions can't be edited") if is_published?
  end
  
  def calculate_statuses
    self.container.calculate_statuses
  end
  
  def build_clone
    new_edition = self.container.build_edition(self.title)

    @@fields_to_clone.each do |attr|
      new_edition.send("#{attr}=", self.send(attr))
    end
     	
    new_edition
  end
  
  def publish(edition,notes)
    self.container.publish(edition,notes)
  end
  
  def is_published?
    container.publishings.any? { |p| p.version_number == self.version_number }
  end
end
