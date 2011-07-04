class Action
  include Mongoid::Document
  
  embedded_in :edition
  
  field :requester_id, :type => Integer
  field :approver_id,  :type => Integer
  field :made,         :type => Time
  field :approved,     :type => Time
  field :comment,      :type => String
  field :request_type, :type => String
  
end
