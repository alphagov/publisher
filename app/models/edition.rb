class Edition
  include Mongoid::Document
  
  include Workflow
    
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  
  def calculate_statuses
    self.container.calculate_statuses
  end
  
  def build_clone
    self.container.build_edition(self.title)
  end
  
  def publish(edition,notes)
    self.container.publish(edition,notes)
  end
  
end