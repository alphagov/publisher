require_dependency "workflow"

require "digest"

class Edition < ApplicationRecord
  include Workflow
  include RecordableActions
  include BaseHelper

  def self.delegated_types
    %w[AnswerEdition GuideEdition TransactionEdition HelpPageEdition SimpleSmartAnswerEdition CompletedTransactionEdition LocalTransactionEdition PlaceEdition PopularLinksEdition]
  end

  delegated_type :editionable, types: delegated_types, dependent: :destroy
  accepts_nested_attributes_for :editionable

  class ResurrectionError < RuntimeError
  end

  delegate_missing_to :editionable

  delegate :introduction, :more_information, :need_to_know, to: :editionable

  belongs_to :assigned_to, class_name: "User", optional: true

  has_many :link_check_reports, dependent: :destroy

  scope :accessible_to,
        lambda { |user|
          return all unless Flipflop.enabled?(:restrict_access_by_org)
          return all if user.gds_editor?
          return all unless user.departmental_editor?

          where(owning_org_content_ids: [user.organisation_content_id])
        }

  # state_machine comes from Workflow
  state_machine.states.map(&:name).each do |state|
    scope state, -> { where(state:) }
  end
  scope :archived_or_published, -> { where(state: %w[archived published]) }
  scope :in_progress, -> { where.not(state: %w[archived published]) }
  scope :assigned_to,
        lambda { |user|
          if user
            where(assigned_to_id: user.id)
          else
            where("assigned_to_id" => nil)
          end
        }
  scope :major_updates, -> { where(major_change: true) }

  scope :slug_title_and_overview_search,
        lambda { |term|
          wildcard_term = "%#{term}%"
          where("title ILIKE ? OR slug ILIKE ? OR overview ILIKE ?", wildcard_term, wildcard_term, wildcard_term)
        }

  # Including recipient_id on actions will include anything that has been
  # assigned to the user we're looking at, but include the check anyway to
  # account for manual assignments

  scope :user_search,
        lambda { |user, term|
          for_user(user).merge(slug_title_and_overview_search(term))
        }

  scope :published, -> { where(state: "published") }
  scope :draft_in_publishing_api, -> { where(state: [PUBLISHING_API_DRAFT_STATES]) }

  scope :in_states, ->(states) { where(state: states) }

  scope :search_title_and_slug,
        lambda { |term|
          wildcard_term = "%#{term}%"
          where("title ILIKE ? OR slug ILIKE ?", wildcard_term, wildcard_term)
        }

  ACTIONS = {
    send_fact_check: "Send to Fact check",
    resend_fact_check: "Resend fact check email",
    request_review: "Send to 2nd pair of eyes",
    schedule_for_publishing: "Schedule for publishing",
    publish: "Send to publish",
    approve_review: "No changes needed",
    request_amendments: "Request amendments",
    approve_fact_check: "Approve fact check",
    skip_review: "Skip review",
  }.freeze

  REVIEW_ACTIONS = ACTIONS.slice(:request_amendments, :approve_review)
  FACT_CHECK_ACTIONS = ACTIONS.slice(:request_amendments, :approve_fact_check)
  CANCEL_SCHEDULED_PUBLISHING_ACTION = {
    cancel_scheduled_publishing: "Cancel scheduled publishing",
  }.freeze
  PUBLISHING_API_DRAFT_STATES = %w[fact_check amends_needed fact_check_received draft ready in_review scheduled_for_publishing].freeze
  EXACT_ROUTE_EDITION_CLASSES = %w[
    HelpPageEdition
  ].freeze
  HAS_GOVSPEAK_FIELDS = %w[
    AnswerEdition
    GuideEdition
    HelpPageEdition
    LicenceEdition
    LocalTransactionEdition
    PlaceEdition
    ProgrammeEdition
    SimpleSmartAnswerEdition
    TransactionEdition
  ].freeze

  validates :title, presence: { message: "Enter a title" }
  validates :version_number, presence: true, uniqueness: { scope: :panopticon_id }, unless: :popular_links_edition?
  validates :panopticon_id, presence: true, unless: :popular_links_edition?
  validates_with ReviewerValidator
  validates :change_note, presence: { if: :major_change }

  before_save do
    check_for_archived_artefact
    remove_line_separator_character
  end

  before_destroy do
    destroy_publishing_api_draft
    destroy_artefact
  end

  after_validation :merge_editionable_errors

  alias_attribute :admin_list_title, :title
  delegate :variant, to: :transaction_edition

  def self.state_names
    state_machine.states.map(&:name)
  end

  def self.for_user(user_id)
    editions = Action.where(requester_id: user_id).or(Action.where(recipient_id: user_id)).map(&:edition)
    Edition.where(id: editions.map(&:id)).or(Edition.where(assigned_to_id: user_id))
  end

  def merge_editionable_errors
    unless editionable.valid?
      editionable.errors.each do |err|
        errors.add(err.attribute, err.message)
        errors.delete("editionable.#{err.attribute}")
      end
    end
  end

  def self.by_format(format)
    edition_class = "#{format}_edition".classify
    Edition.where(editionable_type: edition_class)
  end

  def self.convertible_formats
    Artefact::FORMATS_BY_DEFAULT_OWNING_APP["publisher"] - %w[local_transaction] - Artefact::RETIRED_FORMATS
  end

  def series
    Edition.where(panopticon_id:)
  end

  def history
    series.order([version_number: :desc])
  end

  def siblings
    series.where.not(id:)
  end

  def previous_siblings
    siblings.where("version_number < ?", version_number).order(version_number: "asc")
  end

  def subsequent_siblings
    siblings.where("version_number > ?", version_number).order(version_number: "asc")
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
    history.archived_or_published.major_updates
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
    series.map(&:state).include?("published")
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
    content = if editionable.respond_to?(:indexable_content)
                "#{content} #{editionable.indexable_content}"
              elsif respond_to?(:parts)
                indexable_content_with_parts
              else
                indexable_content_without_parts
              end
    content.strip
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
    if target_class == editionable.class
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
      raise "Cloning of a published edition when an in-progress edition exists is not allowed"
    end

    target_class_attributes = []
    edition_attributes = []
    target_class ||= editionable.class
    fields_to_copy(target_class).each do |attr|
      attribute = []
      attribute << attr.to_sym
      if target_class.has_attribute?(attr)
        attribute << editionable[attr.to_sym]
        target_class_attributes << attribute
      else
        attribute << self[attr.to_sym]
        edition_attributes << attribute
      end
    end

    edition_attributes << [:version_number, get_next_version_number]
    editionable = target_class.build(target_class_attributes.to_h)
    new_edition = Edition.build(edition_attributes.to_h)
    new_edition.editionable = editionable

    # If the type is changing, then take the combined body (whole_body) from
    # the old and decide where to put it in the new.
    #
    # Where the type is not changing, the body will already have been copied
    # above.
    #
    # We don't need to copy parts between Parted types here, because the
    # Parted module does that.
    if target_class != self.editionable.class && !cloning_between_parted_types?(new_edition.editionable)
      new_edition.clone_whole_body_from(self)
    end

    if self.editionable.respond_to?(:copy_to)
      self.editionable.copy_to(new_edition.editionable)
    end

    new_edition.slug = new_edition.slug
                                  &.delete_prefix(self.editionable.slug_prefix)
                                  &.prepend(new_edition.editionable.slug_prefix)

    new_edition
  end

  def clone_whole_body_from(origin_edition)
    if respond_to?(:parts)
      setup_default_parts if respond_to?(:setup_default_parts)
      parts.build(title: "Part One", body: origin_edition.whole_body, slug: "part-one")
    elsif respond_to?(:more_information=)
      editionable.more_information = origin_edition.whole_body
    elsif respond_to?(:body=)
      editionable.body = origin_edition.whole_body
    elsif respond_to?(:licence_overview=)
      editionable.licence_overview = origin_edition.whole_body
    else
      raise "Nowhere to copy whole_body content for conversion from: #{origin_edition.class} to: #{self.class}"
    end
  end

  def cloning_between_parted_types?(new_edition)
    respond_to?(:parts) && new_edition.respond_to?(:parts)
  end

  def self.find_or_create_from_panopticon_data(panopticon_id, importing_user)
    existing_publication = Edition.where(panopticon_id:)
                                  .order(version_number: :desc).first
    return existing_publication if existing_publication

    metadata = Artefact.find(panopticon_id)
    raise "Artefact not found" unless metadata

    importing_user.create_edition(
      metadata.kind.to_sym,
      panopticon_id: metadata.id,
      slug: metadata.slug,
      title: metadata.name,
      assigned_to_id: importing_user.id,
    )
  end

  def self.find_and_identify(slug, edition)
    scope = where(slug:)

    if edition.present? && (edition == "latest")
      scope.order(version_number: :asc).last
    elsif edition.present?
      scope.where(version_number: edition).first
    else
      scope.where(state: "published").order(version_number: :desc).first
    end
  end

  def format
    editionable.class.to_s.gsub("Edition", "")
  end

  def format_name
    if editionable.respond_to?(:format_name)
      editionable.format_name
    else
      format
    end
  end

  def kind_for_artefact
    format.underscore
  end

  def has_video?
    editionable.respond_to?(:has_video?) ? editionable.has_video? : false
  end

  def safe_to_preview?
    !archived?
  end

  def has_sibling_in_progress?
    !sibling_in_progress.nil?
  end

  # Stop broadcasting a delete message unless there are no siblings.
  def broadcast_action(callback_action)
    unless (callback_action == "destroyed") && siblings.any?
      super(callback_action)
    end
  end

  def was_published
    previous_siblings.each { |s| s.perform_event_without_validations_or_timestamp(:archive) }
    notify_siblings_of_published_edition
    update_artefact
  end

  def update_artefact
    check_if_archived
    artefact.update_from_edition(self)
  end

  def update_slug_from_artefact(artefact)
    self.slug = artefact.slug
    save!
  end

  def check_for_archived_artefact
    if panopticon_id
      a = Artefact.find(panopticon_id)
      if (a.state == "archived") && changes.any?
        # If we're only changing the state to archived, that's ok
        # We have to add owning_org_content_ids as Mongo changes the
        # value from nil to an empty array on save - reads as a change
        allowed_keys = %w[state updated_at owning_org_content_ids]
        unless (changes.keys - allowed_keys).empty? && (state == "archived")
          raise "Editing of an edition with an Archived artefact is not allowed"
        end
      end
    end
  end

  def artefact
    @artefact ||= Artefact.find(panopticon_id)
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
      Artefact.find(panopticon_id).destroy!
    end
  end

  def destroy_publishing_api_draft
    return unless can_destroy?

    Services.publishing_api.discard_draft(content_id, locale: artefact.language)
  rescue GdsApi::HTTPNotFound
    nil
  rescue GdsApi::HTTPUnprocessableEntity
    nil
    # This error can also occur when there is no draft to discard
  end

  def exact_route?
    editionable.class.name.in? EXACT_ROUTE_EDITION_CLASSES
  end

  def publish_anonymously!
    if can_publish?
      publish!
      actions.create!(request_type: Action::PUBLISH)
      save! # trigger denormalisation callbacks
    end
  end

  def fact_check_skipped?
    actions.any? && actions.last.request_type == "skip_fact_check"
  end

  def fact_check_email_address
    Publisher::Application.fact_check_config.address
  end

  def check_if_archived
    if artefact.state == "archived"
      raise ResurrectionError, "Cannot register archived artefact '#{artefact.slug}'"
    end
  end

  def content_id
    editionable_type == "PopularLinksEdition" ? editionable.content_id : artefact.content_id
  end

  def latest_link_check_report
    link_check_reports.last
  end

  def remove_line_separator_character
    character = "\u2028"
    if respond_to?(:parts)
      parts.each do |part|
        part.body = part.body.to_s.gsub(character, "")
      end
    elsif respond_to?(:body)
      self.body = body.to_s.gsub(character, "") unless body.nil?
    end
  end

  def paths
    paths = ["/#{slug}"] # base path

    if respond_to?(:parts)
      paths += parts.map { |part| "/#{slug}/#{part.slug}" }
    end

    paths
  end

  def is_accessible_to?(user)
    return true unless Flipflop.enabled?(:restrict_access_by_org)
    return true if user.gds_editor?
    return true unless user.departmental_editor?

    owning_org_content_ids.include?(user.organisation_content_id)
  end

  def is_editable_by?(user)
    !scheduled_for_publishing? && !published? && !archived? && user.has_editor_permissions?(self)
  end

private

  def base_field_keys
    %i[
      title
      editionable_type
      editionable_id
      in_beta
      panopticon_id
      overview
      slug
      owning_org_content_ids
    ]
  end

  def type_specific_field_keys
    (editionable.attribute_names - Edition.attribute_names).map(&:to_sym)
  end

  def common_type_specific_field_keys(target_class)
    ((editionable.attribute_names & target_class.attribute_names) - Edition.attribute_names).map(&:to_sym)
  end

  def popular_links_edition?
    editionable_type == "PopularLinksEdition"
  end
end
