class Publishing
  include Mongoid::Document
  
  embedded_in :guide
  
  field :version_number, :type => Integer
  field :change_notes, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
end
