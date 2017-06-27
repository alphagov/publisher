require_dependency "workflow"
require "search_index_presenter"
require 'digest'

class Edition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Workflow
  include RecordableActions
  include BaseHelper

  class ResurrectionError < RuntimeError
  end

  field :panopticon_id,        type: String
  field :version_number,       type: Integer,  default: 1
  field :sibling_in_progress,  type: Integer,  default: nil

  field :title,                type: String
  field :in_beta,              type: Boolean,  default: false
  field :created_at,           type: DateTime, default: lambda { Time.zone.now }
  field :publish_at,           type: DateTime
  field :overview,             type: String
  field :slug,                 type: String
  field :rejected_count,       type: Integer, default: 0

  field :assignee,             type: String
  field :reviewer,             type: String
  field :creator,              type: String
  field :publisher,            type: String
  field :archiver,             type: String
  field :major_change,         type: Boolean, default: false
  field :change_note,          type: String
  field :review_requested_at,  type: DateTime

  belongs_to :assigned_to, class_name: "User", optional: true

  # state_machine comes from Workflow
  state_machine.states.map(&:name).each do |state|
    scope state, lambda { where(state: state) }
  end
  scope :archived_or_published, lambda { where(:state.in => %w(archived published)) }
  scope :in_progress, lambda { where(:state.nin => %w(archived published)) }
  scope :assigned_to, lambda { |user|
    if user
      where(assigned_to_id: user.id)
    else
      where(:assigned_to_id.exists => false)
    end
  }
  scope :major_updates, lambda { where(major_change: true) }

  scope :internal_search, lambda { |term|
    regex = Regexp.new(Regexp.escape(term), true) # case-insensitive
    any_of({ title: regex }, { slug: regex }, { overview: regex }, licence_identifier: regex)
  }

  # Including recipient_id on actions will include anything that has been
  # assigned to the user we're looking at, but include the check anyway to
  # account for manual assignments
  scope :for_user, lambda { |user|
    any_of(
      { assigned_to_id: user.id },
      { 'actions.requester_id' => user.id },
      'actions.recipient_id' => user.id
    )
  }

  scope :user_search, lambda { |user, term|
    all_of(for_user(user).selector, internal_search(term).selector)
  }

  scope :published, -> { where(state: 'published') }
  scope :draft_in_publishing_api, -> { where(state: { '$in' => PUBLISHING_API_DRAFT_STATES }) }

  ACTIONS = {
    send_fact_check: "Send to Fact check",
    request_review: "Send to 2nd pair of eyes",
    schedule_for_publishing: "Schedule for publishing",
    publish: "Send to publish",
    approve_review: "OK for publication",
    request_amendments: "Request amendments",
    approve_fact_check: "Approve fact check",
    skip_review: "Skip review",
  }.freeze

  REVIEW_ACTIONS = ACTIONS.slice(:request_amendments, :approve_review)
  FACT_CHECK_ACTIONS = ACTIONS.slice(:request_amendments, :approve_fact_check)
  CANCEL_SCHEDULED_PUBLISHING_ACTION = {
    cancel_scheduled_publishing: "Cancel scheduled publishing"
  }.freeze
  PUBLISHING_API_DRAFT_STATES = %w(fact_check amends_needed fact_check_received draft ready in_review scheduled_for_publishing).freeze

  EXACT_ROUTE_EDITION_CLASSES = [
    "CampaignEdition",
    "HelpPageEdition",
    "TransactionEdition"
  ].freeze

  validates :title, presence: true
  validates :version_number, presence: true, uniqueness: { scope: :panopticon_id }
  validates :panopticon_id, presence: true
  validates_with SafeHtml
  validates_with LinkValidator, on: :update, unless: :archived?
  validates_with ReviewerValidator
  validates_presence_of :change_note, if: :major_change

  before_save :check_for_archived_artefact
  before_destroy :destroy_artefact

  index assigned_to_id: 1
  index({ panopticon_id: 1, version_number: 1 }, unique: true)
  index state: 1
  index created_at: 1
  index updated_at: 1

  alias_method :admin_list_title, :title

  def self.state_names
    state_machine.states.map(&:name)
  end

  def self.by_format(format)
    edition_class = "#{format}_edition".classify.constantize
    edition_class.all
  end

  def self.convertible_formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - ["local_transaction"] - Artefact::RETIRED_FORMATS
  end

  def series
    Edition.where(panopticon_id: panopticon_id)
  end

  def history
    series.order([:version_number, :desc])
  end

  def siblings
    series.excludes(id: id)
  end

  def previous_siblings
    siblings.where(:version_number.lt => version_number).order(version_number: "asc")
  end

  def subsequent_siblings
    siblings.where(:version_number.gt => version_number).order(version_number: "asc")
  end

  def latest_edition?
    subsequent_siblings.empty?
  end

  def published_edition
    series.where(state: "published").order(version_number: "desc").first
  end

  def previous_published_edition
    series.where(state: "published").order(version_number: "desc").second
  end

  def in_progress_sibling
    subsequent_siblings.in_progress.order(version_number: "desc").first
  end

  def can_create_new_edition?
    return false if retired_format?
    !scheduled_for_publishing? && subsequent_siblings.in_progress.empty?
  end

  def retired_format?
    Artefact::RETIRED_FORMATS.include? format.underscore
  end

  def major_updates_in_series
    history.published.major_updates
  end

  def latest_major_update
    major_updates_in_series.first
  end

  def latest_change_note
    if latest_major_update.present?
      latest_major_update.change_note
    end
  end

  def public_updated_at
    if latest_major_update.present?
      latest_major_update.updated_at
    elsif has_ever_been_published?
      first_edition_of_published.updated_at
    end
  end

  def has_ever_been_published?
    series.map(&:state).include?('published')
  end

  def first_edition_of_published
    series.archived_or_published.order(version_number: "asc").first
  end

  def meta_data
    PublicationMetadata.new self
  end

  def get_next_version_number
    latest_version = series.order(version_number: "desc").first.version_number
    latest_version + 1
  end

  def indexable_content
    respond_to?(:parts) ? indexable_content_with_parts : indexable_content_without_parts
  end

  def indexable_content_without_parts
    if respond_to?(:body)
      Govspeak::Document.new(body).to_text.to_s.strip
    else
      ""
    end
  end

  def indexable_content_with_parts
    content = indexable_content_without_parts
    return content unless published_edition
    parts.inject([content]) { |acc, part|
      acc.concat([part.title, Govspeak::Document.new(part.body).to_text])
    }.compact.join(" ").strip
  end

  # If the new clone is of the same type, we can copy all its fields over; if
  # we are changing the type of the edition, any fields other than the base
  # fields will likely be meaningless.
  def fields_to_copy(target_class)
    if target_class == self.class
      base_field_keys + type_specific_field_keys
    else
      base_field_keys + common_type_specific_field_keys(target_class)
    end
  end

  def build_clone(target_class = nil)
    unless state == "published"
      raise "Cloning of non published edition not allowed"
    end
    unless can_create_new_edition?
      raise "Cloning of a published edition when an in-progress edition exists
             is not allowed"
    end

    target_class = self.class unless target_class
    new_edition = target_class.new(version_number: get_next_version_number)

    fields_to_copy(target_class).each do |attr|
      new_edition[attr] = read_attribute(attr)
    end

    # If the type is changing, then take the combined body (whole_body) from
    # the old and decide where to put it in the new.
    #
    # Where the type is not changing, the body will already have been copied
    # above.
    #
    # We don't need to copy parts between Parted types here, because the
    # Parted module does that.
    if target_class != self.class && !cloning_between_parted_types?(new_edition)
      new_edition.clone_whole_body_from(self)
    end

    new_edition
  end

  def clone_whole_body_from(origin_edition)
    if self.respond_to?(:parts)
      self.setup_default_parts if self.respond_to?(:setup_default_parts)
      self.parts.build(title: "Part One", body: origin_edition.whole_body, slug: "part-one")
    elsif self.respond_to?(:more_information=)
      self.more_information = origin_edition.whole_body
    elsif self.respond_to?(:body=)
      self.body = origin_edition.whole_body
    elsif self.respond_to?(:licence_overview=)
      self.licence_overview = origin_edition.whole_body
    else
      raise "Nowhere to copy whole_body content for conversion from: #{origin_edition.class} to: #{self.class}"
    end
  end

  def cloning_between_parted_types?(new_edition)
    self.respond_to?(:parts) && new_edition.respond_to?(:parts)
  end

  def self.find_or_create_from_panopticon_data(panopticon_id, importing_user)
    existing_publication = Edition.where(panopticon_id: panopticon_id)
      .order_by(version_number: :desc).first
    return existing_publication if existing_publication

    metadata = Artefact.find(panopticon_id)
    raise "Artefact not found" unless metadata

    importing_user.create_edition(metadata.kind.to_sym,
      panopticon_id: metadata.id,
      slug: metadata.slug,
      title: metadata.name)
  end

  def self.find_and_identify(slug, edition)
    scope = where(slug: slug)

    if edition.present? && (edition == "latest")
      scope.order_by(version_number: :asc).last
    elsif edition.present?
      scope.where(version_number: edition).first # rubocop:disable Rails/FindBy
    else
      scope.where(state: "published").order(version_number: :desc).first
    end
  end

  def format
    self.class.to_s.gsub("Edition", "")
  end

  def format_name
    format
  end

  def has_video?
    false
  end

  def safe_to_preview?
    !archived?
  end

  def has_sibling_in_progress?
    !sibling_in_progress.nil?
  end

  # Stop broadcasting a delete message unless there are no siblings.
  def broadcast_action(callback_action)
    unless (callback_action == "destroyed") && self.siblings.any?
      super(callback_action)
    end
  end

  def was_published
    previous_siblings.each { |s| s.perform_event_without_validations(:archive) }
    notify_siblings_of_published_edition
    update_artefact
  end

  def update_artefact
    check_if_archived
    artefact.update_from_edition(self)
  end

  def update_slug_from_artefact(artefact)
    self.slug = artefact.slug
    self.save!
  end

  def check_for_archived_artefact
    if panopticon_id
      a = Artefact.find(panopticon_id)
      if (a.state == "archived") && changes.any?
        # If we're only changing the state to archived, that's ok
        # Any other changes are not allowed
        allowed_keys = %w(state updated_at)
        unless (changes.keys - allowed_keys).empty? && (state == "archived")
          raise "Editing of an edition with an Archived artefact is not allowed"
        end
      end
    end
  end

  def artefact
    @_artefact ||= Artefact.find(self.panopticon_id)
  end

  # When we delete an edition is the only one in its series
  # we delete the associated artefact to remove all trace of the
  # item from the system.
  #
  # We don't do this by notifying panopticon as this will only ever
  # happen for artefacts representing editions that haven't been
  # published (and therefore aren't registered in the rest of the)
  # system.
  def destroy_artefact
    if can_destroy? && siblings.empty?
      Artefact.find(self.panopticon_id).destroy
    end
  end

  def exact_route?
    self.class.name.in? EXACT_ROUTE_EDITION_CLASSES
  end

  def publish_anonymously!
    if can_publish?
      publish!
      actions.create!(request_type: Action::PUBLISH)
      save! # trigger denormalisation callbacks
    end
  end

  def fact_check_skipped?
    actions.any? && actions.last.request_type == 'skip_fact_check'
  end

  def fact_check_email_address
    Publisher::Application.fact_check_config.address(self.id)
  end

  def check_if_archived
    if artefact.state == "archived"
      raise ResurrectionError, "Cannot register archived artefact '#{artefact.slug}'"
    end
  end

  def register_with_rummager
    check_if_archived
    presenter = SearchIndexPresenter.new(self)
    SearchIndexer.call(presenter)
  end

  def auth_bypass_id
    @_auth_bypass_id ||= begin
      ary = Digest::SHA256.digest(id.to_s).unpack('NnnnnN')
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end
  end

  def content_id
    artefact.content_id
  end

private

  def base_field_keys
    [
      :title,
      :panopticon_id,
      :overview,
      :slug,
    ]
  end

  def type_specific_field_keys
    (self.fields.keys - Edition.fields.keys).map(&:to_sym)
  end

  def common_type_specific_field_keys(target_class)
    ((self.fields.keys & target_class.fields.keys) - Edition.fields.keys).map(&:to_sym)
  end
end
