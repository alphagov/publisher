class Part
  include Mongoid::Document

  embedded_in :guide
  embedded_in :programme

  field :order, :type => Integer
  field :title, :type => String
  field :body, :type => String
  field :slug, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }

  validates_presence_of :title
  validates_presence_of :slug
end
