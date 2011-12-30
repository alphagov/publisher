require 'rest_client'
require 'marples/model_action_broadcast'

class Publication
  include Mongoid::Document
  include Mongoid::Timestamps
  include Marples::ModelActionBroadcast

  class CannotDeletePublishedPublication < RuntimeError;
  end

  field :panopticon_id, :type => Integer

  field :name, :type => String
  field :slug, :type => String
  field :section, :type => String
  field :department, :type => String

  field :rejected_count, :type => Integer, default: 0
  field :edition_rejected_count, :type => Integer, default: 0

  embeds_many :publishings

  scope :lined_up,            where('editions.state' => 'lined_up')
  scope :draft,               where('editions.state' => 'draft')
  scope :amends_needed,       where('editions.state' => 'amends_needed')
  scope :in_review,           where('editions.state' => 'in_review')
  scope :fact_check,          where('editions.state' => 'fact_check')
  scope :fact_check_received, where('editions.state' => 'fact_check_received')
  scope :ready,               where('editions.state' => 'ready')
  scope :published,           where('editions.state' => 'published')
  scope :archived,            where('editions.state' => 'archived')
  scope :assigned_to,         lambda { |user| user.nil? ? where(:"editions.assigned_to_id".exists => false) : where('editions.assigned_to_id' => user.id) }

  index "editions.assigned_to_id"

  after_initialize :create_first_edition

  before_destroy :check_can_delete_and_notify
  after_destroy :remove_from_search_index

  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }

  # map each edition state to a "has_{state}?" method
  Edition.state_machine.states.map(&:name).each do |state|
    define_method "has_#{state}?" do
      (self.editions.where(state: state).count > 0)
    end
  end

  def format_type
    self.class.name.to_s
  end

  def self.create_from_panopticon_data(panopticon_id, importing_user)
    require 'gds_api/panopticon'
    api = GdsApi::Panopticon.new(Plek.current.environment)
    metadata = api.artefact_for_slug(panopticon_id)
    raise "Artefact not found" if metadata.nil?

    existing_publication = Publication.where(slug: metadata.slug).first
    if existing_publication.present?
      existing_publication.update_attribute(:panopticon_id, metadata.id)
      return existing_publication
    end

    importing_user.create_publication(metadata.kind.to_sym, :panopticon_id => metadata.id, :name => metadata.name,
      :slug => metadata.slug, :title => metadata.title)
  end

  def self.find_and_identify_edition(slug, edition)
    publication = where(slug: slug).first
    return nil if publication.nil?
    if edition.present?
      # This is used for previewing yet-to-be-published editions.
      # At some point this should require special authentication.
      if edition == "latest"
        publication.editions.order_by(:created_at => :desc).first
      else
        publication.editions.select { |e| e.version_number.to_i == edition.to_i }.first
      end
    else
      publication.published_edition
    end
  end

  def panopticon_uri
    Plek.current.find("arbiter") + '/artefacts/' + (panopticon_id || slug).to_s
  end

  def meta_data
    PublicationMetadata.new self
  end

  def build_edition(title)
    version_number = editions.length + 1
    edition = editions.create(:title=> title, :version_number=>version_number, :state=>'draft')
    edition
  end

  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << self.class.edition_class.new(:title => self.name, :state => 'lined_up')
    end
  end

  def mark_as_rejected
    self.inc(:edition_rejected_count, 1)
    self.inc(:rejected_count, 1)
  end

  def mark_as_accepted
    self.update_attribute(:edition_rejected_count, 0)
  end

  def publish(edition, notes)
    publishings.create version_number: edition.version_number, change_notes: notes
    update_in_search_index
  end

  def published_edition
    latest_publishing = self.editions.where(state: 'published').sort_by(&:version_number).last
  rescue
    nil
  end

  def actions
    self.editions.all.map{ |edition| edition.actions }
  end

  def archived_editions
    self.editions.where(state: 'archived').sort_by(&:version_number)
  end

  def last_archived_edition
    last_archived_edition = archived_editions.last
  rescue
    nil
  end

  def can_create_new_edition?
    !self.has_draft?
  end

  def can_destroy?
    !self.has_published?
  end

  def has_video?
    false
  end

  def safe_to_preview?
    true
  end

  def latest_edition
    self.editions.sort_by(&:version_number).last
  rescue
    nil
  end

  def title
    self.name || latest_edition.title
  end

  def indexable_content
    published_edition ? published_edition.alternative_title : ""
  end

  def search_index
    {
      "title" => title,
      "link" => "/#{slug}",
      "section" => section ? section.parameterize : nil,
      "format" => _type.downcase,
      "description" => (published_edition && published_edition.overview) || "",
      "indexable_content" => indexable_content,
    }
  end

  def self.search_index_all
    all.map(&:search_index)
  end

  private
  def check_can_delete_and_notify
    if !self.can_destroy?
      raise CannotDeletePublishedPublication
      false
    end
  end

  def update_in_search_index
    Rummageable.index self.search_index
  end

  def remove_from_search_index
    Rummageable.delete "/#{slug}"
  end
end
