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

  alias_method :admin_list_title, :title
  before_save :update_container_timestamp

  def fact_check_id
    [ container.id.to_s, id.to_s, version_number ].join '/'
  end

  def fact_check_email_address
    "factcheck+#{Plek.current.environment}-#{container.id}@alphagov.co.uk"
  end

  def build_clone
    new_edition = container.build_edition(self.title)
    real_fields_to_merge = self.class.fields_to_clone + [:overview, :alternative_title]

    real_fields_to_merge.each do |attr|
      new_edition.send("#{attr}=", read_attribute(attr))
    end

    new_edition
  end

  def update_container_timestamp
    if self.container.created_at
      container.updated_at = Time.now
      container.save
    end
  end
end
