class Publishing
  include Mongoid::Document
  include Mongoid::Timestamps
  
  embedded_in :guide
  
  field :version_number, :type => Integer
  field :change_notes, :type => String
end
