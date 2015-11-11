require "edition"
require "registerable_edition"
require 'gds_api/panopticon'

class Edition
  include BaseHelper

  class ResurrectionError < RuntimeError
  end

  ACTIONS = {
    send_fact_check: "Send to Fact check",
    request_review: "Send to 2nd pair of eyes",
    schedule_for_publishing: "Schedule for publishing",
    publish: "Send to publish",
    approve_review: "OK for publication",
    request_amendments: "Request amendments",
    approve_fact_check: "Approve fact check"
  }
  REVIEW_ACTIONS = ACTIONS.slice(:request_amendments, :approve_review)
  FACT_CHECK_ACTIONS = ACTIONS.slice(:request_amendments, :approve_fact_check)
  CANCEL_SCHEDULED_PUBLISHING_ACTION = {
    cancel_scheduled_publishing: "Cancel scheduled publishing"
  }

  def self.state_names
    state_machine.states.map &:name
  end

  scope :internal_search, lambda { |term|
    regex = Regexp.new(Regexp.escape(term), true)  # case-insensitive
    any_of({title: regex}, {slug: regex}, {overview: regex}, {licence_identifier: regex})
  }

  # Including recipient_id on actions will include anything that has been
  # assigned to the user we're looking at, but include the check anyway to
  # account for manual assignments
  scope :for_user, lambda { |user|
    any_of(
      { assigned_to_id: user.id },
      { 'actions.requester_id' => user.id },
      { 'actions.recipient_id' => user.id }
    )
  }

  scope :user_search, lambda { |user, term|
    all_of(for_user(user).selector, internal_search(term).selector)
  }

  def publish_anonymously!
    if can_publish?
      publish!
      actions.create!(request_type: Action::PUBLISH)
      save! # trigger denormalisation callbacks
    end
  end

  alias_method :was_published_without_indexing, :was_published
  # `was_published` is called from the state machine in govuk_content_models
  # when the edition state changes to `published`
  def was_published
    was_published_without_indexing
    register_with_panopticon
    notify_publishing_api
  end

  def fact_check_skipped?
    actions.any? and actions.last.request_type == 'skip_fact_check'
  end

  def fact_check_email_address
    Publisher::Application.fact_check_config.address(self.id)
  end

  def register_with_panopticon
    artefact = Artefact.find(self.panopticon_id)
    if artefact.state == "archived"
      raise ResurrectionError, "Cannot register archived artefact '#{artefact.slug}'"
    end

    format_as_kind = self.format.underscore
    registerer = GdsApi::Panopticon::Registerer.new(owning_app: "publisher", rendering_app: "frontend", kind: format_as_kind)
    details = RegisterableEdition.new(self)
    registerer.register(details)
  end

  def notify_publishing_api
    PublishingAPINotifier.perform_async(self.id.to_s)
  end

  def self.conversion_classes
    classes = Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - ["local_transaction"]
    classes.map{|c| (c + "_edition").titleize }
  end

end
