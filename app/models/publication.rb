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
  field :tags, :type => String
  field :audiences, :type => Array

  field :has_drafts, :type => Boolean
  field :has_fact_checking, :type => Boolean
  field :has_published, :type => Boolean
  field :has_reviewables, :type => Boolean
  field :archived, :type => Boolean
  field :lined_up, :type => Boolean

  field :section, :type => String
  field :department, :type => String
  field :related_items, :type => String

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
  scope :assigned_to, lambda { |user| assignment_filter(user) }

  after_initialize :create_first_edition

  #before_save :calculate_statuses
  before_save :denormalise_metadata
  before_destroy :check_can_delete_and_notify
  after_destroy :remove_from_search_index

  # validates_presence_of :panopticon_id

  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }

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

  # map each edition state to a "has_{state}?" method
  Edition.state_machine.states.map(&:name).each do |state|
    define_method "has_#{state}?" do
      (self.editions.where(state: state).count > 0)
    end
  end

  def self.import panopticon_id, importing_user
    uri = "#{Plek.current.find("arbiter")}/artefacts/#{panopticon_id}.js"
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
    publication = importing_user.create_publication kind.to_sym, :panopticon_id => json['id'], :name => json['name']
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

  def self.assignment_filter(user)
    expr = if user
             %{assignment && assignment.recipient_id == "#{user.id}"}
           else
             %{!assignment}
           end
    where(%{
      function(){
        var last = function(a){ return a && a[a.length - 1]; }
        var edition = last(this.editions);
        if (!edition) { return false; }
        var assignment = last((edition.actions || []).filter(function(a){
          return a.request_type == "#{Action::ASSIGN}";
        }));
        return #{expr};
      }
    })
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
      self.editions << self.class.edition_class.new(:title => self.name)
      self.lined_up = true
    end
  end

  def mark_as_started
    self.lined_up = false
    true
  end

  def mark_as_rejected
    self.inc(:edition_rejected_count, 1)
    self.inc(:rejected_count, 1)
  end

  def mark_as_accepted
    self.update_attribute(:edition_rejected_count, 0)
  end

  def calculate_statuses
    self.has_published = self.publishings.any? && !self.archived

    published_versions = ::Set.new(publishings.map(&:version_number))
    all_versions = ::Set.new(editions.map(&:version_number))
    drafts = (all_versions - published_versions)

    self.has_fact_checking = editions.any? { |e| e.status_is?(Action::FACT_CHECK_REQUESTED) }

    self.has_reviewables = editions.any? { |e| e.status_is?(Action::REVIEW_REQUESTED) }

    true
  end

  def publish(edition, notes)
    publishings.create version_number: edition.version_number, change_notes: notes
    update_in_search_index
  end

  def denormalise_metadata
    meta_data.apply_to self
  end

  def published_edition
    latest_publishing = self.editions.where(state: 'published').sort_by(&:version_number).last
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

  def latest_edition
    self.editions.sort_by(&:created_at).last
  rescue
    nil
  end

  def title
    self.name || latest_edition.title
  end

  FORMAT = "this._type"
  SECTION = "this.section"
  DEPARTMENT = "this.department"

  def self.count_by(type = FORMAT)

    map = <<-EOF
      function() {
        var truthy = function(value) {
          return (value == true) ? 1 : 0;
        };

        emit(#{type}, {
          type:   #{type},
          count:      1,
          draft:      truthy(this.has_drafts),
          lined_up:   truthy(this.lined_up),
          review:     truthy(this.has_reviewables),
          published:  truthy(this.has_published),
          fact_check: truthy(this.has_fact_checking),
          archived:   truthy(this.archived)
        });
      }
    EOF

    reduce = <<-EOF
      function(key, values) {
        var count      = 0,
            draft      = 0,
            lined_up   = 0,
            review     = 0,
            published  = 0,
            fact_check = 0,
            archived   = 0;

        values.forEach(function(doc) {
          count      += parseInt(doc.count);
          draft      += parseInt(doc.draft);
          lined_up   += parseInt(doc.lined_up);
          published  += parseInt(doc.published);
          review     += parseInt(doc.review);
          fact_check += parseInt(doc.fact_check);
          archived   += parseInt(doc.archived);
          type = doc.type
        });

        return {
          type:       type,
          count:      count,
          draft:      draft,
          lined_up:   lined_up,
          review:     review,
          published:  published,
          fact_check: fact_check,
          archived:   archived
        };
      }
    EOF

    collection.mapreduce(map, reduce, out: "mr_publications_count_by_#{type}").find()
  end

  def indexable_content
    published_edition ? published_edition.alternative_title : ""
  end

  def search_index
    {
      "title" => title,
      "link" => "/#{slug}",
      "format" => _type.downcase,
      "description" => (published_edition && published_edition.overview) || "",
      "indexable_content" => indexable_content,
    }
  end

  def self.search_index_published
    published.map(&:search_index)
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
