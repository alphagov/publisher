module Workflow

  extend ActiveSupport::Concern

  included do
    embeds_many :actions
  end

  def new_action(user, type, options={})
    action = Action.new(options.merge(:requester_id=>user.id, :request_type=>type))
    self.actions << action
    #self.calculate_statuses
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
    assignment = most_recent_action { |a| Action::ASSIGN == a.request_type }
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

    if ['request_review','approve_review','approve_fact_check','request_amendments','send_fact_check','receive_fact_check','publish','archive','new_version'].include?(activity)
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
