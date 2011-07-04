class Part
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :guide
  
  field :order, :type => Integer
  field :title, :type => String
  field :excerpt, :type => String
  field :body, :type => String
  field :slug, :type => String
end
