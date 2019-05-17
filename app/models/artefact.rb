require "plek"
require "artefact_action" # Require this when running outside Rails
require_dependency "safe_html"

class Artefact
  include Mongoid::Document
  include Mongoid::Timestamps

  field "name",                 type: String
  field "slug",                 type: String
  field "paths",                type: Array, default: []
  field "prefixes",             type: Array, default: []
  field "kind",                 type: String
  field "owning_app",           type: String
  field "rendering_app",        type: String
  field "active",               type: Boolean, default: false

  field "publication_id",       type: String
  field "description",          type: String
  field "state",                type: String,  default: "draft"
  field "language",             type: String,  default: "en"
  field "latest_change_note",   type: String
  field "public_timestamp",     type: DateTime
  field "redirect_url",         type: String

  # content_id should be unique but we have existing artefacts without it.
  # We should therefore enforce the uniqueness as soon as:
  #  - every current artefact will have a content id assigned
  #  - every future artefact will be created with a content id
  field "content_id",           type: String

  index({ slug: 1 }, unique: true)

  # This index allows the `relatable_artefacts` method to use an index-covered
  # query, so it doesn't have to load each of the artefacts.
  index name: 1,
        state: 1,
        kind: 1,
        _type: 1,
        _id: 1

  scope :not_archived, lambda { where(:state.nin => %w[archived]) }

  FORMATS_BY_DEFAULT_OWNING_APP = {
    "publisher"               => %w(answer
                                    campaign
                                    completed_transaction
                                    guide
                                    help_page
                                    licence
                                    local_transaction
                                    place
                                    programme
                                    simple_smart_answer
                                    transaction
                                    video),
    "smartanswers"            => ["smart-answer"],
    "custom-application"      => ["custom-application"], # In this case the owning_app is overriden. eg calendars, licencefinder
    "travel-advice-publisher" => ["travel-advice"],
    "specialist-publisher"    => %w[manual],
    "finder-api"              => %w(finder
                                    finder_email_signup),
    # business support was converted into a format owned by specialist publisher
    # but it's not a direct swap so we don't claim that is the owning app
    "replaced"                => %w[business_support],
  }.freeze

  RETIRED_FORMATS = %w[campaign programme video].freeze

  FORMATS = FORMATS_BY_DEFAULT_OWNING_APP.values.flatten

  def self.default_app_for_format(format)
    FORMATS_BY_DEFAULT_OWNING_APP.detect { |_app, formats| formats.include?(format) }.first
  end

  KIND_TRANSLATIONS = {
    "standard transaction link"        => "transaction",
    "local authority transaction link" => "local_transaction",
    "completed/done transaction" => "completed_transaction",
    "benefit / scheme"                 => "programme",
    "find my nearest"                  => "place",
  }.tap { |h| h.default_proc = ->(_, k) { k } }.freeze

  MULTIPART_FORMATS = %w(guide local_transaction licence simple_smart_answer).freeze

  embeds_many :actions, class_name: "ArtefactAction", order: { created_at: :asc }

  embeds_many :external_links, class_name: "ArtefactExternalLink"
  accepts_nested_attributes_for :external_links, allow_destroy: true,
    reject_if: proc { |attrs| attrs["title"].blank? && attrs["url"].blank? }

  before_validation :normalise, on: :create
  before_create :record_create_action
  before_update :record_update_action
  after_update :update_editions
  before_destroy :discard_publishing_api_draft

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, slug: true
  validates :kind, inclusion: { in: lambda { |_x| FORMATS } }
  validates :state, inclusion: { in: %w(draft live archived) }
  validates :owning_app, presence: true
  validates :language, inclusion: { in: %w(en cy) }
  validate :validate_prefixes_and_paths

  def self.in_alphabetical_order
    order_by(name: :asc)
  end

  def self.find_by_slug(slug)
    where(slug: slug).first
  end

  def self.multipart_formats
    where(kind: { '$in' => MULTIPART_FORMATS })
  end

  def self.archived
    where(state: 'archived')
  end

  def self.with_redirect
    where(:redirect_url.nin => [nil, ""])
  end

  # Fallback to english if no language is present
  def language
    attributes['language'] || "en"
  end

  def normalise
    return if kind.blank?

    self.kind = KIND_TRANSLATIONS[kind.to_s.downcase.strip]
  end

  def as_json(options = {})
    super.tap { |hash|
      hash["id"] = hash.delete("_id")
    }
  end

  def any_editions_published?
    Edition.where(panopticon_id: self.id, state: 'published').any?
  end

  def any_editions_ever_published?
    Edition.where(panopticon_id: self.id,
                  :state.in => %w(published archived)).any?
  end

  def update_editions
    return archive_editions if state == 'archived'

    if self.slug_changed?
      Edition.draft_in_publishing_api.where(panopticon_id: self.id).each do |edition|
        edition.update_slug_from_artefact(self)
      end
    end
  end

  def archive_editions
    if state == 'archived'
      Edition.where(panopticon_id: self.id, :state.nin => %w[archived]).each do |edition|
        edition.new_action(self, "note", comment: "Artefact has been archived. Archiving this edition.")
        edition.perform_event_without_validations(:archive!)
      end
    end
  end

  def self.from_param(slug_or_id)
    find_by(slug: slug_or_id) || find(slug_or_id)
  end

  def update_attributes_as(user, *args)
    assign_attributes(*args)
    save_as user
  end

  def save_as(user, options = {})
    default_action = new_record? ? "create" : "update"
    action_type = options.delete(:action_type) || default_action
    record_action(action_type, user: user)
    save(options)
  end

  # We should use this method when performing save actions from rake tasks,
  # message queue consumer or any other performed tasks that have no user associated
  # as we are still interested to know what triggered the action.
  def save_as_task!(task_name, options = {})
    default_action = new_record? ? "create" : "update"
    action_type = options.delete(:action_type) || default_action

    record_action(action_type, task_name: task_name)
    save!(options)
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
    last_snapshot = actions.last.snapshot if actions.last

    unless current_snapshot == last_snapshot

      attributes = {
        action_type: action_type,
        snapshot: current_snapshot,
      }

      attributes[:user] = user if user
      attributes[:task_performed_by] = task_name if task_name

      new_action = actions.build(attributes)
      # Mongoid will not fire creation callbacks on embedded documents, so we
      # need to trigger this manually. There is a `cascade_callbacks` option on
      # `embeds_many`, but it doesn't appear to trigger creation events on
      # children when an update event fires on the parent
      new_action.set_created_at
    end
  end

  def archived?
    self.state == "archived"
  end

  def live?
    self.state == "live"
  end

  def snapshot
    attributes
      .except("_id", "created_at", "updated_at", "actions")
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
    update(
      state: state_from_edition(edition),
      description: edition.overview,
      public_timestamp: edition.public_updated_at
    )
  end

  def downtime
    Downtime.for(self)
  end

  def exact_route?
    le = latest_edition
    return le.exact_route? if le.present?
    return edition_class_name.in? Edition::EXACT_ROUTE_EDITION_CLASSES if owning_app == 'publisher'

    prefixes.empty?
  end

private

  def edition_class_name
    "#{kind.camelcase}Edition"
  end

  def validate_prefixes_and_paths
    if ! self.prefixes.nil? && self.prefixes_changed?
      if self.prefixes.any? { |p| ! valid_url_path?(p) }
        errors.add(:prefixes, "are not all valid absolute URL paths")
      end
    end
    if ! self.paths.nil? && self.paths_changed?
      if self.paths.any? { |p| ! valid_url_path?(p) }
        errors.add(:paths, "are not all valid absolute URL paths")
      end
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
    when 'published' then 'live'
    when 'archived' then 'archived'
    else 'draft'
    end
  end

  def discard_publishing_api_draft
    Services.publishing_api.discard_draft(self.content_id)
  rescue GdsApi::HTTPNotFound
    nil
  end
end
