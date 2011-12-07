class Edition
  include Mongoid::Document

  include Workflow

  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  field :overview, :type => String
  field :alternative_title, :type => String
  field :state, :type => String

  state_machine :initial => :lined_up do

    after_transition :on => :request_amendments do |edition, transition|
      edition.container.mark_as_rejected
    end 
    after_transition :on => :approve_review do |edition, transition|
      edition.container.mark_as_accepted
    end 
    before_transition :on => :publish do |edition, transition|
      edition.container.editions.where(state: 'published').all.each{|e| e.archive }    
    end                                                                                
    after_transition :on => :publish do |edition, transition|
      edition.container.update_in_search_index
    end

    event :start_work do
      transition :lined_up => :draft
    end

    event :request_review do
      transition [:draft, :amends_needed] => :in_review
    end

    event :approve_review do
      transition :in_review => :ready
    end

    event :approve_fact_check do
      transition :fact_check_received => :ready
    end

    event :request_amendments do
      transition [:fact_check_received, :in_review] => :amends_needed
    end

    event :send_fact_check do
      transition :ready => :fact_check
    end

    event :receive_fact_check do
      transition :fact_check => :fact_check_received
    end

    event :publish do
      # allow draft to be published as emergency, but do not expose in UI for now
      transition [:draft, :ready] => :published
    end

    event :archive do
      transition :published => :archived
    end

  end

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  validate :not_editing_published_item
  alias_method :admin_list_title, :title
  before_save :update_container_timestamp

  before_destroy :do_not_delete_if_published

  def fact_check_id
    [ container.id.to_s, id.to_s, version_number ].join '/'
  end

  def not_editing_published_item
    errors.add(:base, "Published editions can't be edited") if changed? and !state_changed? and published?
  end

  def build_clone
    new_edition = container.build_edition(self.title)

    self.class.fields_to_clone.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end

    new_edition
  end

  def capitalized_state_name
    self.human_state_name.capitalize
  end

  def created_by
    creation = actions.detect { |a| a.request_type == Action::CREATE || a.request_type == Action::NEW_VERSION }
    creation.requester if creation
  end

  def published_by
    publication = actions.detect { |a| a.request_type == Action::PUBLISH }
    publication.requester if publication
  end

  def archived_by
    publication = actions.detect { |a| a.request_type == Action::ARCHIVE }
    publication.requester if publication
  end                                     

  def latest_status_action
    self.actions.where(:request_type.ne => 'note').last
  end

  def fact_check_email_address
    "factcheck+#{Plek.current.environment}-#{container.id}@alphagov.co.uk"
  end

  def is_published?
    self.published?
  end

  def fact_checked?
    (self.actions.where(request_type: Action::APPROVE_FACT_CHECK).count > 0)
  end

  def do_not_delete_if_published
    (!self.published?)
  end

  def update_container_timestamp
    if self.container.created_at
      container.updated_at = Time.now
      container.save
    end
  end

  def unpublish!
    self.container.publishings.detect { |p| p.version_number == self.version_number }.destroy
    self.actions.each do |a|
      unless a.request_type == Action::NEW_VERSION or a.request_type == Action::CREATED
        a.destroy
      end
    end
    self.container.save
  end
end
