class Action
  include Mongoid::Document
  
  CREATED, REVIEW_REQUESTED, PUBLISHED, NEW_VERSION, OKAYED, REVIEWED = 
      "created", "review_requested", "published", "new_version", "okayed", "reviewed"

  embedded_in :edition
  
  field :requester_id, :type => Integer
  field :approver_id,  :type => Integer
  field :approved,     :type => DateTime
  field :comment,      :type => String
  field :request_type, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  
  def requester
    @requester ||= User.find(self.requester_id)
  rescue
    nil
  end
end
