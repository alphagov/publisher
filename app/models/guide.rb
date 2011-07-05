class Guide
  include Mongoid::Document
  include Mongoid::Timestamps
  
  after_initialize :create_first_edition
  
  field :slug,        :type => String
  field :tags,        :type => String
  field :is_business, :type => Boolean
  
  embeds_many :editions
  embeds_many :publishings
  
  def title
    self.editions.any? ? self.editions.last.title : 'Title TBD'
  end

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
    self.publishings.build(:version_number=>edition.version_number,:change_notes=>notes)
    self.save!
  end
  
  def published_edition
    latest_publishing = self.publishings.first
    if latest_publishing
      self.editions.first {|s| s.version_number == latest_publishing.version_number }
    else
      nil
    end
  end
  
  def latest_edition
    self.editions.sort(&:created_at).last
  end
  
end
