require "edition"
require "search_index_presenter"
require 'digest'

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
  PUBLISHING_API_DRAFT_STATES = %w(fact_check amends_needed fact_check_received draft ready in_review scheduled_for_publishing).freeze

  MIGRATED_EDITION_CLASSES = [
    AnswerEdition,
    GuideEdition,
    HelpPageEdition,
    LocalTransactionEdition,
    SimpleSmartAnswerEdition,
  ].freeze

  EXACT_ROUTE_EDITION_CLASSES = [
    CampaignEdition,
    HelpPageEdition,
    TransactionEdition
  ].freeze

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

  def migrated?
    self.class.in? MIGRATED_EDITION_CLASSES
  end

  def exact_route?
    self.class.in? EXACT_ROUTE_EDITION_CLASSES
  end

  def publish_anonymously!
    if can_publish?
      publish!
      actions.create!(request_type: Action::PUBLISH)
      save! # trigger denormalisation callbacks
    end
  end

  def self.by_format(format)
    edition_class = "#{format}_edition".classify.constantize
    edition_class.all
  end

  scope :published, -> { where(state: 'published') }
  scope :draft_in_publishing_api, -> { where(state: { '$in' => PUBLISHING_API_DRAFT_STATES }) }

  alias_method :was_published_without_indexing, :was_published
  # `was_published` is called from the state machine in govuk_content_models
  # when the edition state changes to `published`
  def was_published
    was_published_without_indexing
    update_artefact
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

  def update_artefact
    check_if_archived
    artefact.update_from_edition(self)
  end

  def register_with_rummager
    check_if_archived
    presenter = SearchIndexPresenter.new(self)
    SearchIndexer.call(presenter)
  end

  def artefact
    @_artefact ||= Artefact.find(self.panopticon_id)
  end

  def self.convertible_formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - ["local_transaction"]
  end

  def fact_check_id
    if migrated?
      ary = Digest::SHA256.digest(id.to_s).unpack('NnnnnN')
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end
  end
end
