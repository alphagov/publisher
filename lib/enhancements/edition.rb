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
    approve_fact_check: "Approve fact check",
    skip_review: "Skip review",
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
    update_artefact
    notify_publishing_platform_services
  end

  def notify_publishing_platform_services
    register_with_rummager
    notify_publishing_api
  end

  def fact_check_skipped?
    actions.any? and actions.last.request_type == 'skip_fact_check'
  end

  def fact_check_email_address
    Publisher::Application.fact_check_config.address(self.id)
  end

  def check_if_archived
    if artefact.state == "archived"
      raise ResurrectionError, "Cannot register archived artefact '#{artefact.slug}'"
    end
  end

  def register_exact_route?
    [TransactionEdition, CampaignEdition, HelpPageEdition].include? self.class
  end

  def paths
    if register_exact_route?
      ["/#{slug}", "/#{slug}.json"]
    else
      ["/#{slug}.json"]
    end
  end

  def prefixes
    if register_exact_route?
      []
    else
      ["/#{slug}"]
    end
  end

  def update_artefact
    check_if_archived
    artefact.update_from_edition(self)
  end

  def register_with_router_api
    check_if_archived
    RoutableArtefact.new(artefact).submit
  end

  def register_with_rummager
    check_if_archived
    registerable_edition = RegisterableEdition.new(self)
    SearchIndexer.call(registerable_edition)
  end

  def notify_publishing_api
    PublishingAPIPublisher.perform_async(self.id.to_s)
  end

  def artefact
    @_artefact ||= Artefact.find(self.panopticon_id)
  end

  def self.convertible_formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - ["local_transaction"]
  end
end
