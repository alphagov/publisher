module Workflow
  
  extend ActiveSupport::Concern
  
  included do 
    embeds_many :actions
  end
  
  def can_request_review?
     latest_action &&  
     latest_action.request_type != Action::REVIEW_REQUESTED && 
     latest_action.request_type != Action::PUBLISHED
   end

   def can_review?
     latest_action && Action::REVIEW_REQUESTED == latest_action.request_type
   end

   def can_publish?
     latest_action && Action::OKAYED == latest_action.request_type
   end

   def can_okay?
     latest_action && Action::REVIEW_REQUESTED == latest_action.request_type
   end

   def new_action(user,type,comment)
     action = Action.new(:requester_id=>user.id,:request_type=>type,:comment=>comment)
     self.actions << action
     self.calculate_statuses
     action
   end

   def latest_action
     self.actions.sort_by(&:created_at).last
   end
end