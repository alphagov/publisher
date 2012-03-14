class ProgrammeEdition < WholeEdition
  include Parted

  before_save :setup_default_parts, :on => :create
  
  @fields_to_clone = []

  DEFAULT_PARTS = [
    {:title => "Overview", :slug => "overview"},
    {:title => "What you'll get", :slug => "what-youll-get"},
    {:title => "Eligibility", :slug => "eligibility"},
    {:title => "How to claim", :slug => "how-to-claim"},
    {:title => "Further information", :slug => "further-information"},
  ]

  def setup_default_parts
    if parts.empty?
      DEFAULT_PARTS.each { |part|
        parts.build(:title => part[:title], :slug => part[:slug], :body => "")
      }
    end
  end
end
