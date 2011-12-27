module Workflow
  class CannotDeletePublishedPublication < RuntimeError; end
  extend ActiveSupport::Concern

  included do
    validate :not_editing_published_item
    before_destroy :check_can_delete_and_notify
    
    field :state, :type => String, :default => 'lined_up'
    belongs_to :assigned_to, :class_name => 'User'
    embeds_many :actions

    state_machine :initial => :lined_up do
      after_transition :on => :request_amendments do |edition, transition|
        edition.mark_as_rejected
      end

      # after_transition :on => :approve_review do |edition, transition|
      #   edition.mark_as_accepted
      # end

      after_transition :on => :publish do |edition, transition|
        edition.previous_siblings.all.each(&:archive)
        edition.update_in_search_index
      end

      event :start_work do
        transition :lined_up => :draft
      end

      event :request_review do
        transition [:draft, :amends_needed] => :in_review
      end

      event :approve_review do
        transition :in_review => :ready
      end

      event :approve_fact_check do
        transition :fact_check_received => :ready
      end

      event :request_amendments do
        transition [:fact_check_received, :in_review] => :amends_needed
      end

      event :send_fact_check do
        transition :ready => :fact_check
      end

      event :receive_fact_check do
        transition :fact_check => :fact_check_received
      end

      event :publish do
        transition :ready => :published
      end

      event :emergency_publish do
        transition :draft => :published
      end

      event :archive do
        transition :published => :archived
      end
    end
  end

  def fact_checked?
    (self.actions.where(request_type: Action::APPROVE_FACT_CHECK).count > 0)
  end

  def capitalized_state_name
    self.human_state_name.capitalize
  end

  def created_by
    creation = actions.detect { |a| a.request_type == Action::CREATE || a.request_type == Action::NEW_VERSION }
    creation.requester if creation
  end

  def published_by
    publication = actions.where(request_type: Action::PUBLISH).first
    publication.requester if publication
  end

  def archived_by
    publication = actions.where(request_type: Action::ARCHIVE).first
    publication.requester if publication
  end

  def latest_status_action(type = nil)
    if type
      self.actions.where(:request_type => type).last
    else
      most_recent_action(&:status_action?)
    end
  end

  def new_action(user, type, options={})
    actions.create!(options.merge(requester_id: user.id, request_type: type))
  end

  def most_recent_action(&blk)
    self.actions.sort_by(&:created_at).reverse.find(&blk)
  end

  def not_editing_published_item
    if changed? and published? and ! state_changed?
      errors.add(:base, "Published editions can't be edited") 
    end
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

    save if result
  end

  def can_destroy?
    ! published? and ! archived?
  end
  
  def check_can_delete_and_notify
    raise CannotDeletePublishedPublication unless can_destroy?
  end
  
  def mark_as_rejected
    self.inc(:rejected_count, 1)
  end
end
