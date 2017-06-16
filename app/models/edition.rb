require_dependency "workflow"

class Edition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Workflow
  include RecordableActions

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
    Artefact.find(panopticon_id)
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
