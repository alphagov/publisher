class Part
  include Mongoid::Document

  embedded_in :guide_edition
  embedded_in :programme_edition

  field :order, :type => Integer
  field :title, :type => String
  field :body, :type => String
  field :slug, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }

  validates_presence_of :title
  validates_presence_of :slug
  validates_exclusion_of :slug, :in => ["video"], :message => "Can not be video"
end
