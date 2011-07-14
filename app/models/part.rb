class Part
  include Mongoid::Document
  
  embedded_in :guide
  
  field :order, :type => Integer
  field :title, :type => String
  field :body, :type => String
  field :slug, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  
end
