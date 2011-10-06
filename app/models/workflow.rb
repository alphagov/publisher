module Workflow

  extend ActiveSupport::Concern

  included do 
    embeds_many :actions
  end

  def can_request_review?
    not status_is?(Action::FACT_CHECK_REQUESTED, Action::REVIEW_REQUESTED, Action::PUBLISHED)
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

  def most_recent_action(&blk)
    self.actions.sort_by(&:created_at).reverse.find(&blk)
  end

  def progress(activity, current_user,notes)
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
    else
      raise "Unknown progress activity: #{activity}"
    end

    self.container.save!
  end

end
