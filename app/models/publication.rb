class Publication
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,            :type => String
  field :slug,            :type => String
  field :tags,            :type => String
  field :audiences,       :type => Array

  field :has_drafts,      :type => Boolean
  field :has_published,   :type => Boolean
  field :has_reviewables, :type => Boolean
  field :archived,        :type => Boolean

  embeds_many :publishings

  scope :in_draft,         where(has_drafts: true)
  scope :published,        where(has_published: true)
  scope :review_requested, where(has_reviewables: true)
  scope :archive,          where(archived: true)

  after_initialize :create_first_edition

  before_save :calculate_statuses

  validates_presence_of :name
  validates_presence_of :slug

  accepts_nested_attributes_for :editions, :reject_if => proc { |a| a['title'].blank? }

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

     self.has_reviewables = editions.any? {|e| e.latest_action && e.latest_action.request_type == Action::REVIEW_REQUESTED }

     true
  end

  def publish(edition,notes)
    self.publishings << Publishing.new(:version_number=>edition.version_number,:change_notes=>notes)
    calculate_statuses
  end

  def published_edition
    latest_publishing = self.publishings.first
    if latest_publishing
      self.editions.first {|s| s.version_number == latest_publishing.version_number }
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

end