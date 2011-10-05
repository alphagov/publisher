module Workflow

  extend ActiveSupport::Concern

  included do 
    embeds_many :actions
  end

  def can_request_review?
    not latest_action_is(Action::FACT_CHECK_REQUESTED, Action::REVIEW_REQUESTED, Action::PUBLISHED)
  end

  def in_review?
    can_review? && can_okay?
  end

  def in_fact_checking?
    latest_action_is(Action::FACT_CHECK_REQUESTED)
  end

  def can_review?
    latest_action_is(Action::REVIEW_REQUESTED)
  end

  def can_request_fact_check?
    not latest_action_is(Action::FACT_CHECK_REQUESTED, Action::PUBLISHED)
  end

  def can_publish?
    latest_action_is(Action::OKAYED)
  end

  def can_okay?
    latest_action_is(Action::REVIEW_REQUESTED)
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

  def latest_action_is(*kinds)
    action = latest_action
    action && kinds.include?(action.request_type)
  end

  def progress(activity,current_user,notes)
    case activity
    when 'request_fact_check'
      current_user.request_fact_check(self, notes)
    when 'fact_check_received'
      current_user.receive_fact_check(self, notes)
    when 'request_review'
      current_user.request_review(self, notes)
    when 'review'
      current_user.review(self, notes)
    when 'okay'
      current_user.okay(self, notes)
    when 'publish'
      current_user.publish(self, notes)
    end

    self.container.save
  end

end
