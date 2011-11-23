class Programme < Publication
  embeds_many :editions, :class_name => 'ProgrammeEdition', :inverse_of => :programme

  include Parted

  DEFAULT_PARTS = [
	{:title => "Overview", :slug => "overview"},
	{:title => "What you'll get", :slug => "what-youll-get"},
	{:title => "Eligibility", :slug => "eligibility"},
	{:title => "How to claim", :slug => "how-to-claim"},
	{:title => "Further information", :slug => "further-information"},
  ]

  def self.edition_class
    ProgrammeEdition
  end

  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << self.class.edition_class.new(:title => self.name)
     DEFAULT_PARTS.each { |part|
        self.editions.first.parts.build(:title => part[:title],:slug => part[:slug], :body => " ")
      }                    
    end
  end
end
