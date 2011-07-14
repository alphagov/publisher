class Edition
  include Mongoid::Document
  
  include Workflow
  
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
end