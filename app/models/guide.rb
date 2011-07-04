class Guide
  include Mongoid::Document
  include Mongoid::Timestamps
  
  after_initialize :create_first_edition
  
  field :slug,        :type => String
  field :tags,        :type => String
  field :is_business, :type => Boolean
  
  embeds_many :editions
  embeds_many :publishings
  
  def build_edition(title,introduction)
    version_number = self.editions.length + 1
    self.editions.build(:title=> title, :introduction => introduction,:version_number=>version_number)
  end
  
  def create_first_edition
    unless self.persisted?
      self.editions.build()
    end
  end
  
  def publish!(edition,notes)
    self.publishings.create(:version_number=>version.version_number,:change_notes=>notes)
  end
  
  def published_edition
    latest_publishing = self.publishings.find(sort:[["created_at DESC"]])
    if latest_publishing
      self.editions.first(:version_number => latest_publishing.version_number)
    else
      nil
    end
  end
  
end
