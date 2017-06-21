require "state_machines-mongoid"

module Workflow
  class CannotDeletePublishedPublication < RuntimeError; end
  extend ActiveSupport::Concern

  included do
    validate :not_editing_published_item
    before_destroy :check_can_delete_and_notify
    after_destroy :notify_siblings_of_published_edition

    before_save :denormalise_users!
    after_create :notify_siblings_of_new_edition

    field :state, type: String, default: "draft"
    belongs_to :assigned_to, class_name: "User", optional: true

    state_machine initial: :draft do
      after_transition on: :request_amendments do |edition, _transition|
        edition.mark_as_rejected
      end

      before_transition on: :schedule_for_publishing do |edition, transition|
        edition.publish_at = transition.args.first
      end

      before_transition on: [:publish, :cancel_scheduled_publishing] do |edition, _transition|
        edition.publish_at = nil
      end

      before_transition on: [:approve_review, :skip_review, :request_amendments] do |edition, _transition|
        edition.reviewer = nil
      end

      after_transition on: :publish do |edition, _transition|
        edition.was_published
      end

      before_transition on: :request_review do |edition, _transition|
        edition.review_requested_at = Time.zone.now
      end

      event :request_review do
        transition [:draft, :amends_needed] => :in_review
      end

      event :approve_review do
        transition in_review: :ready
      end

      event :approve_fact_check do
        transition fact_check_received: :ready
      end

      event :request_amendments do
        transition [:fact_check_received, :in_review, :ready, :fact_check] => :amends_needed
      end

      event :skip_review do
        transition in_review: :ready
      end

      # Editions can optionally be sent out for fact check
      event :send_fact_check do
        transition [:ready, :fact_check_received] => :fact_check
      end

      # If no response is received to a fact check request we can skip
      # that fact check and return the edition to the 'ready' state
      event :skip_fact_check do
        transition fact_check: :ready
      end

      # Where a fact check response has been received the item is moved
      # into a special state so that the fact check responses can be
      # reviewed
      event :receive_fact_check do
        transition fact_check: :fact_check_received
      end

      event :schedule_for_publishing do
        transition ready: :scheduled_for_publishing
      end

      event :cancel_scheduled_publishing do
        transition scheduled_for_publishing: :ready
      end

      event :publish do
        transition [:ready, :scheduled_for_publishing] => :published
      end

      event :archive do
        transition all => :archived, :unless => :archived?
      end

      state :in_review do
        validates_presence_of :review_requested_at
      end

      state :scheduled_for_publishing do
        validates_presence_of :publish_at
        validate :publish_at_is_in_the_future
      end
    end
  end

  def fact_checked?
    self.actions.where(request_type: Action::APPROVE_FACT_CHECK).count.positive?
  end

  def status_text
    text = human_state_name.capitalize
    text += ' on ' + publish_at.strftime("%d/%m/%Y %H:%M") if scheduled_for_publishing?
    text
  end

  def denormalise_users!
    new_assignee = assigned_to.try(:name)
    set(assignee: new_assignee) unless new_assignee == assignee
    update_user_action("creator",   [Action::CREATE, Action::NEW_VERSION])
    update_user_action("publisher", [Action::PUBLISH])
    update_user_action("archiver",  [Action::ARCHIVE])
    self
  end

  def can_destroy?
    ! scheduled_for_publishing? && ! published? && ! archived?
  end

  def check_can_delete_and_notify
    raise CannotDeletePublishedPublication unless can_destroy?
  end

  def mark_as_rejected
    self.inc(rejected_count: 1)
  end

  def previous_edition
    self.previous_published_edition || false
  end

  def notify_siblings_of_new_edition
    siblings.update_all(sibling_in_progress: self.version_number)
  end

  def in_progress?
    ! %w(archived published).include? self.state
  end

  def locked_for_edits?
    scheduled_for_publishing? || published?
  end

  def error_description
    published? ? 'Published editions' : 'Editions scheduled for publishing'
  end

  def perform_event_without_validations(event)
    # http://rubydoc.info/github/pluginaweek/state_machine/StateMachine/Machine:event
    # pass false to transition state without performing state machine actions
    public_send(event, false)
    save(validate: false)
  end

  def important_note
    action = actions.where(:request_type.in => [Action::IMPORTANT_NOTE, Action::IMPORTANT_NOTE_RESOLVED]).last
    action if action.try(:request_type) == Action::IMPORTANT_NOTE
  end

private

  def notify_siblings_of_published_edition
    siblings.update_all(sibling_in_progress: nil)
  end

  def update_sibling_in_progress(version_number_or_nil)
    update_attribute(:sibling_in_progress, version_number_or_nil)
  end

  def update_user_action(property, statuses)
    actions.where(:request_type.in => statuses).limit(1).each do |action|
      # This can be invoked by Panopticon when it updates an artefact and associated
      # editions. The problem is that Panopticon and Publisher users live in different
      # collections, but share a model and relationships with eg actions.
      # Therefore, Panopticon might not find a user for an action.
      if action.requester
        set(property => action.requester.name)
      end
    end
  end

  def publish_at_is_in_the_future
    errors.add(:publish_at, "can't be a time in the past") if publish_at.present? && publish_at < Time.zone.now
  end

  def not_editing_published_item
    return if changes.none? || state_changed?

    errors.add(:base, "Archived editions can't be edited") if archived?

    return unless locked_for_edits?
    errors.add(:base, "#{error_description} can't be edited") if disallowable_change?
  end

  def disallowable_change?
    allowed_to_change = %w(slug publish_at)
    (changes.keys - allowed_to_change).present?
  end
end
