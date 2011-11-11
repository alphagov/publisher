module Workflow

  extend ActiveSupport::Concern

  included do
    embeds_many :actions
  end

  def can_request_review?
    not status_is?(Action::REVIEW_REQUESTED, Action::PUBLISHED)
  end

  def in_review?
    can_review? && can_okay?
  end

  def in_fact_checking?
    status_is?(Action::FACT_CHECK_REQUESTED)
  end

  def can_review?
    status_is?(Action::REVIEW_REQUESTED)
  end

  def can_request_fact_check?
    not status_is?(Action::FACT_CHECK_REQUESTED, Action::PUBLISHED)
  end

  def can_publish?
    status_is?(Action::OKAYED)
  end

  def can_okay?
    status_is?(Action::REVIEW_REQUESTED)
  end

  def new_action(user, type, options={})
    action = Action.new(options.merge(:requester_id=>user.id, :request_type=>type))
    self.actions << action
    self.calculate_statuses
    action
  end

  def latest_status_action
    most_recent_action(&:status_action?)
  end

  def status_is?(*kinds)
    action = latest_status_action
    action && kinds.include?(action.request_type)
  end

  def assigned_to
    assignment = most_recent_action { |a| Action::ASSIGNED == a.request_type }
    assignment && assignment.recipient
  end

  def assigned_to_id
    a = assigned_to
    a && a.id
  end

  def most_recent_action(&blk)
    self.actions.sort_by(&:created_at).reverse.find(&blk)
  end

  def progress(activity_details, current_user)
    activity = activity_details.delete(:request_type)

    if ['request_fact_check', 'fact_check_received', 'request_review', 'review', 'okay', 'publish'].include?(activity)
      result = current_user.send(activity, self, activity_details)
    elsif activity == 'start_work'
      result = current_user.start_work(self)
    else
      raise "Unknown progress activity: #{activity}"
    end
    
    if result
      self.container.save! 
    else
      result
    end
  end

end
