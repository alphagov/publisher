class Edition
  include Mongoid::Document

  include Workflow

  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  field :overview, :type => String
  field :alternative_title, :type => String

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
    errors.add(:base, "Published editions can't be edited") if changed? and is_published?
  end

  def calculate_statuses
    self.container.calculate_statuses
  end

  def build_clone
    new_edition = container.build_edition(self.title)

    self.class.fields_to_clone.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end

    new_edition
  end

  def publish(edition,notes)
    self.container.publish(edition,notes)
  end

  def is_published?
    container.publishings.any? { |p| p.version_number == self.version_number }
  end

  def has_been_reviewed?
    latest_status_action.request_type == "reviewed" if latest_status_action
  end

  def has_been_okayed?
    latest_status_action.request_type == "okayed" if latest_status_action
  end

  def created_by
    creation = actions.detect { |a| a.request_type == Action::CREATED || a.request_type == Action::NEW_VERSION }
    creation.requester if creation
  end

  def published_by
    publication = actions.detect { |a| a.request_type == Action::PUBLISHED }
    publication.requester if publication
  end
  
  def do_not_delete_if_published
    if self.is_published?
      false
    else
      true
    end
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
