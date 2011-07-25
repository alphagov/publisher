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
  
  def friendly_description
    case request_type
    when CREATED
      "#{edition.container.class} created by #{requester.name}."
    when NEW_VERSION
      "New version \"#{edition.title}\" created by #{requester.name}."
    when REVIEW_REQUESTED
      "A review and publish was requested by #{requester.name}."
    when REVIEWED
      "Reviewed by #{requester.name}. Not OK'd for publication."
    when OKAYED
      "OK'd for publication by #{requester.name}."
    when PUBLISHED
      "Published."
    end
  end
  
  def requester
    @requester ||= User.find(self.requester_id)
  rescue
    nil
  end
  
  def to_s
    request_type.humanize.capitalize
  end
end
