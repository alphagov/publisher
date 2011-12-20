class ProgrammeEdition < WholeEdition
  embeds_many :parts

  accepts_nested_attributes_for :parts, :allow_destroy => true, :reject_if => :all_blank

  @fields_to_clone = []

  def build_clone
    new_edition = super
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end

  def order_parts
    ordered_parts = parts.sort_by { |p| p.order ? p.order : 99999 }
    ordered_parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end

  DEFAULT_PARTS = [
    {:title => "Overview", :slug => "overview"},
    {:title => "What you'll get", :slug => "what-youll-get"},
    {:title => "Eligibility", :slug => "eligibility"},
    {:title => "How to claim", :slug => "how-to-claim"},
    {:title => "Further information", :slug => "further-information"},
  ]

  def create_first_edition
    unless self.persisted?
      self.editions << self.class.new(:title => self.name)
      DEFAULT_PARTS.each { |part|
        self.editions.first.parts.build(:title => part[:title],:slug => part[:slug], :body => " ")
      }                    
    end
  end
end
