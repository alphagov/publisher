class Edition

  include Mongoid::Document
  include Workflow

  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  field :overview, :type => String
  field :alternative_title, :type => String
  field :slug, :type => String
  field :section, :type => String
  field :department, :type => String
  field :rejected_count, :type => Integer, default: 0
  field :panopticon_id, :type => Integer

  validates :title, presence: true
  validates :version_number, presence: true
  validates :panopticon_id, presence: true

  embeds_many :actions

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  alias_method :admin_list_title, :title
  before_save :update_container_timestamp

  def fact_check_id
    [ container.id.to_s, id.to_s, version_number ].join '/'
  end

  def fact_check_email_address
    "factcheck+#{Plek.current.environment}-#{container.id}@alphagov.co.uk"
  end
  
  def last_fact_checked_at
    last_fact_check = actions.reverse.find(&:is_fact_check_request?)
    last_fact_check ? last_fact_check.created_at : NullTimestamp.new
  end

  def build_clone
    new_edition = container.build_edition(self.title)
    real_fields_to_merge = self.class.fields_to_clone + [:overview, :alternative_title]

    real_fields_to_merge.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end

    new_edition
  end

  scope :lined_up,            where('state' => 'lined_up')
  scope :draft,               where('state' => 'draft')
  scope :amends_needed,       where('state' => 'amends_needed')
  scope :in_review,           where('state' => 'in_review')
  scope :fact_check,          where('state' => 'fact_check')
  scope :fact_check_received, where('state' => 'fact_check_received')
  scope :ready,               where('state' => 'ready')
  scope :published,           where('state' => 'published')
  scope :archived,            where('state' => 'archived')
  scope :assigned_to,         lambda { |user| user.nil? ? where(:assigned_to_id.exists => false) : where('editions.assigned_to_id' => user.id) }

  index "assigned_to_id"
  index "state"

  before_destroy :check_can_delete_and_notify
  after_destroy :remove_from_search_index

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
      existing_publication.panopticon_id ||= metadata.id
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

  def archived_editions
    self.editions.where(state: 'archived').sort_by(&:version_number)
  end

  def last_archived_edition
    last_archived_edition = archived_editions.last
  rescue
    nil
  end

  def can_create_new_edition?
    ! draft?
  end

  def can_destroy?
    ! published?
  end

  def has_video?
    false
  end

  def safe_to_preview?
    true
  end

  def indexable_content
    published? ? alternative_title : ""
  end

  def search_index
    {
      "title" => title,
      "link" => "/#{slug}",
      "section" => section ? section.parameterize : nil,
      "format" => _type.downcase,
      "description" => (published? && overview) || "",
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
