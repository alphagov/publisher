require "plek"
require "artefact_action" # Require this when running outside Rails
require_dependency "safe_html"

class Artefact < ApplicationRecord
  strip_attributes only: :redirect_url

  scope :not_archived, -> { where.not(state: %w[archived]) }

  FORMATS_BY_DEFAULT_OWNING_APP = {
    "publisher" => %w[answer
                      completed_transaction
                      guide
                      help_page
                      local_transaction
                      place
                      simple_smart_answer
                      transaction],

    "smartanswers" => %w[smart-answer],
    "custom-application" => %w[custom-application], # In this case the owning_app is overriden. eg calendars, licencefinder
    "specialist-publisher" => %w[manual],
    "finder-api" => %w[finder
                       finder_email_signup],
    # business support was converted into a format owned by specialist publisher
    # but it's not a direct swap so we don't claim that is the owning app
    "replaced" => %w[business_support],
  }.freeze

  RETIRED_FORMATS = %w[campaign programme video licence].freeze

  FORMATS = FORMATS_BY_DEFAULT_OWNING_APP.values.flatten

  def self.default_app_for_format(format)
    FORMATS_BY_DEFAULT_OWNING_APP.detect { |_app, formats| formats.include?(format) }.first
  end

  KIND_TRANSLATIONS = {
    "standard transaction link" => "transaction",
    "local authority transaction link" => "local_transaction",
    "completed/done transaction" => "completed_transaction",
    "benefit / scheme" => "programme",
    "find my nearest" => "place",
  }.tap { |h| h.default_proc = ->(_, k) { k } }.freeze

  has_many :artefact_actions, -> { order(created_at: :asc) }, class_name: "ArtefactAction", dependent: :destroy

  has_many :external_links, class_name: "ArtefactExternalLink"
  accepts_nested_attributes_for :external_links,
                                allow_destroy: true,
                                reject_if: proc { |attrs| attrs["title"].blank? && attrs["url"].blank? }

  before_validation :normalise, on: :create
  before_create :record_create_action
  before_update :record_update_action
  after_update :update_editions

  validates :name, presence: { message: "Enter a title" }
  validates :slug, presence: { message: "Enter a slug" }, uniqueness: true, slug: true
  validates :kind, inclusion: { in: ->(_x) { FORMATS }, message: "Select a format" }
  validates :state, inclusion: { in: %w[draft live archived] }
  validates :owning_app, presence: true
  validates :language, inclusion: { in: %w[en cy] }
  validate :validate_prefixes_and_paths

  def self.in_alphabetical_order
    order_by(name: :asc)
  end

  def self.find_by_slug(slug)
    where(slug:).first
  end

  # Fallback to english if no language is present
  def language
    attributes["language"] || "en"
  end

  def welsh?
    language == "cy"
  end

  def normalise
    return if kind.blank?

    self.kind = KIND_TRANSLATIONS[kind.to_s.downcase.strip]
  end

  def as_json(options = {})
    super.tap do |hash|
      hash["id"] = hash.delete("_id")
    end
  end

  def any_editions_published?
    Edition.where(panopticon_id: id, state: "published").any?
  end

  def any_editions_ever_published?
    Edition.where(
      panopticon_id: id,
      :state.in => %w[published archived],
    ).any?
  end

  def update_editions
    return archive_editions if state == "archived"

    if saved_change_to_attribute?("slug")
      Edition.draft_in_publishing_api.where(panopticon_id: id).find_each do |edition|
        edition.update_slug_from_artefact(self)
      end
    end
  end

  def archive_editions
    if state == "archived"
      Edition.where(panopticon_id: id).where.not(state: %w[archived]).find_each do |edition|
        edition.new_action(artefact_actions.last.user, "note", comment: "Artefact has been archived. Archiving this edition.")
        edition.perform_event_without_validations_or_timestamp(:archive!)
      end
    end
  end

  def self.from_param(slug_or_id)
    find_by(slug: slug_or_id) || find(slug_or_id)
  end

  def update_as(user, *args)
    assign_attributes(*args)
    save_as user
  end

  # 'valid?' populates the error context for the instance which is used in caller chain to show errors
  def save_as(user, options = {})
    default_action = new_record? ? "create" : "update"
    action_type = options.delete(:action_type) || default_action
    record_action(action_type, user:)

    save! if valid?
  end

  # We should use this method when performing save actions from rake tasks,
  # message queue consumer or any other performed tasks that have no user associated
  # as we are still interested to know what triggered the action.
  def save_as_task!(task_name, options = {})
    default_action = new_record? ? "create" : "update"
    action_type = options.delete(:action_type) || default_action
    record_action(action_type, task_name:)

    save! if valid?
  end

  def record_create_action
    record_action "create"
  end

  def record_update_action
    record_action "update"
  end

  def record_action(action_type, options = {})
    user = options[:user]
    task_name = options[:task_name]
    current_snapshot = snapshot
    last_snapshot = artefact_actions.last.snapshot if artefact_actions.last

    unless current_snapshot == last_snapshot

      attributes = {
        action_type:,
        snapshot: current_snapshot,
      }

      attributes[:user] = user if user
      attributes[:task_performed_by] = task_name if task_name

      artefact_actions.build(attributes)
    end
  end

  def archived?
    state == "archived"
  end

  def live?
    state == "live"
  end

  def snapshot
    attributes
      .except("id", "created_at", "updated_at", "artefact_actions")
  end

  def latest_edition
    Edition
      .where(panopticon_id: id)
      .order(version_number: :desc)
      .first
  end

  def latest_edition_id
    edition = latest_edition
    edition.id.to_s if edition
  end

  def update_from_edition(edition)
    update!(
      state: state_from_edition(edition),
      description: edition.overview,
      public_timestamp: edition.public_updated_at,
    )
  end

  def downtime
    Downtime.for(self)
  end

  def exact_route?
    le = latest_edition
    return le.exact_route? if le.present?
    return edition_class_name.in? Edition::EXACT_ROUTE_EDITION_CLASSES if owning_app == "publisher"

    prefixes.empty?
  end

private

  def edition_class_name
    "#{kind.camelcase}Edition"
  end

  def validate_prefixes_and_paths
    if !prefixes.nil? && prefixes_changed? && prefixes.any? { |p| !valid_url_path?(p) }
      errors.add(:prefixes, "are not all valid absolute URL paths")
    end
    if !paths.nil? && paths_changed? && paths.any? { |p| !valid_url_path?(p) }
      errors.add(:paths, "are not all valid absolute URL paths")
    end
  end

  def valid_url_path?(path)
    return false unless path.starts_with?("/")

    uri = URI.parse(path)
    uri.path == path && path !~ %r{//} && path !~ %r{./\z}
  rescue URI::InvalidURIError
    false
  end

  def state_from_edition(edition)
    case edition.state
    when "published" then "live"
    when "archived" then "archived"
    else "draft"
    end
  end
end
