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

      after_transition :on => :publish do |edition, transition|
        #maybe edition.previous_siblings.where(:published).each would work better
        #additionally may need transitions from each state to archived
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

    # alias_method :created_by, :creator
    # alias_method :published_by, :publisher
    # alias_method :archived_by, :archiver
  end

  def fact_checked?
    (self.actions.where(request_type: Action::APPROVE_FACT_CHECK).count > 0)
  end

  def capitalized_state_name
    self.human_state_name.capitalize
  end

  def denormalise_users!
    create_action = actions.where(:request_type.in => [Action::CREATE, Action::NEW_VERSION]).first
    publish_action = actions.where(:request_type => Action::PUBLISH).first
    archive_action = actions.where(:request_type => Action::ARCHIVE).first

    self.assignee = assigned_to.name if assigned_to
    self.creator = create_action.requester.name if create_action and create_action.requester
    self.publisher = publish_action.requester.name if publish_action and publish_action.requester
    self.archiver = archive_action.requester.name if archive_action and archive_action.requester

    save!(:validate => false) and reload
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

  def can_destroy?
    ! published? and ! archived?
  end
  
  def check_can_delete_and_notify
    raise CannotDeletePublishedPublication unless can_destroy?
  end
    
  def mark_as_rejected
    self.inc(:rejected_count, 1)
  end

  def previous_edition
    self.previous_published_edition || false
  end

  def edition_changes
    self.whole_body.empty? ? false : Differ.diff_by_line( self.whole_body, self.published_edition.whole_body )
  end

end
