class Publication
  include Mongoid::Document
  include Mongoid::Timestamps

  field :panopticon_id,   :type => Integer

  field :name,            :type => String
  field :slug,            :type => String
  field :tags,            :type => String
  field :audiences,       :type => Array

  field :has_drafts,      :type => Boolean
  field :has_fact_checking, :type => Boolean
  field :has_published,   :type => Boolean
  field :has_reviewables, :type => Boolean
  field :archived,        :type => Boolean

  field :section,         :type => String
  field :related_items,   :type => String

  embeds_many :publishings

  scope :in_draft,         where(has_drafts: true)
  scope :fact_checking,    where(has_fact_checking: true)
  scope :published,        where(has_published: true)
  scope :review_requested, where(has_reviewables: true)
  scope :archive,          where(archived: true)

  after_initialize :create_first_edition

  before_save :calculate_statuses

  validates_presence_of :name

  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }

  def self.import panopticon_id, importing_user
    uri = Plek.current.find("arbiter") + '/artefacts/' + panopticon_id + '.js'
    data = open(uri).read
    json = JSON.parse data
    publication = Publication.where(slug: json['slug']).first
    if publication.present?
      return publication if publication.panopticon_id
      publication.panopticon_id = json['id']
      publication.save!
      return publication
    end

    kind = json['kind']
    publication = importing_user.send "create_#{kind}", :panopticon_id => json['id'], :name => json['name']
    publication.save!
    publication
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
    version_number = self.editions.length + 1
    edition = self.class.edition_class.new(:title=> title, :version_number=>version_number)
    self.editions << edition
    calculate_statuses
    edition
  end

  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << self.class.edition_class.new(:title => self.name)
      calculate_statuses
    end
  end

  def calculate_statuses
    self.has_published = self.publishings.any? && ! self.archived

    published_versions = ::Set.new(publishings.map(&:version_number))
    all_versions = ::Set.new(editions.map(&:version_number))
    drafts = (all_versions - published_versions)
    self.has_drafts = drafts.any?

    self.has_fact_checking = editions.any? { |e| e.status_is?(Action::FACT_CHECK_REQUESTED) }

    self.has_reviewables = editions.any? {|e| e.status_is?(Action::REVIEW_REQUESTED) }

    true
  end

  def publish(edition, notes)
    denormalise_metadata
    self.publishings << Publishing.new(:version_number=>edition.version_number,:change_notes=>notes)
    calculate_statuses
  end

  def denormalise_metadata
    meta_data.apply_to self
  end
  private :denormalise_metadata

  def published_edition
    latest_publishing = self.publishings.sort_by(&:version_number).last
    if latest_publishing
      self.editions.detect {|s| s.version_number == latest_publishing.version_number }
    else
      nil
    end
  end

  def can_create_new_edition?
    return !self.has_drafts
  end

  def can_destroy?
    return !self.has_published
  end

  def latest_edition
    self.editions.sort_by(&:created_at).last
  end

  def title
    self.name || latest_edition.title
  end

  FORMAT = "this._type"
  SECTION = "this.section"

  def self.count_by(type = FORMAT) 

    map = <<EOF
      function() {
        function truthy(value) {
          return (value == true) ? 1 : 0;
        }
        emit(#{type}, {type: #{type}, count: 1, draft: truthy(this.has_drafts), review: truthy(this.has_reviewables), published: truthy(this.has_published), fact_check: truthy(this.has_fact_checking)})
      }
EOF
    reduce = <<EOF
      function(key, values) {
        var count = 0; draft = 0; review = 0; published = 0; fact_check = 0;
        values.forEach(function(doc) { 
          count += parseInt(doc.count);
          draft += parseInt(doc.draft);
          published += parseInt(doc.published);
          review += parseInt(doc.review);
          fact_check += parseInt(doc.fact_check);
          type = doc.type
        });
        return {type: type, count: count, draft: draft, review: review, published: published, fact_check: fact_check}
      }
EOF

    collection.mapreduce(map, reduce).find()

  end

  AUDIENCES = [
    "Age-related audiences",
    "Carers",
    "Civil partnerships",
    "Crime and justice-related audiences",
    "Disabled people",
    "Employment-related audiences",
    "Family-related audiences",
    "Graduates",
    "Gypsies and travellers",
    "Horse owners",
    "Intermediaries",
    "International audiences",
    "Long-term sick",
    "Members of the Armed Forces",
    "Nationality-related audiences",
    "Older people",
    "Partners of people claiming benefits",
    "Partners of students",
    "People of working age",
    "People on a low income",
    "Personal representatives (for a deceased person)",
    "Property-related audiences",
    "Road users",
    "Same-sex couples",
    "Single people",
    "Smallholders",
    "Students",
    "Terminally ill",
    "Trustees",
    "Veterans",
    "Visitors to the UK",
    "Volunteers",
    "Widowers",
    "Widows",
    "Young people"
  ]
  SECTIONS = [
    'Rights',
    'Justice',
    'Education and skills',
    'Work',
    'Family',
    'Money',
    'Taxes',
    'Benefits and schemes',
    'Driving',
    'Housing',
    'Communities',
    'Pensions',
    'Disabled people',
    'Travel',
    'Citizenship'
  ]
end
