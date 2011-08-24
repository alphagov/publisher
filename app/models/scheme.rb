class Scheme < Publication
  embeds_many :editions, :class_name => 'SchemeEdition', :inverse_of => :scheme

  def self.edition_class
    SchemeEdition
  end

  def create_first_edition
    unless self.persisted? or self.editions.any?
      self.editions << self.class.edition_class.new(:title => self.name)
      [
        {:title => "Overview", :slug => "overview"},
        {:title => "How to claim", :slug => "how-to-claim"},
        {:title => "What you'll get", :slug => "what-youll-get"},
        {:title => "Eligibility", :slug => "eligibility"},
        {:title => "How your claim is worked out", :slug => "how-your-claim-is-worked-out"},
        {:title => "What can affect your benefit", :slug => "what-can-affect-your-benefit"},
      ].each { |part|
        self.editions.first.parts.build(:title => part[:title],:slug => part[:slug], :body => " ")
      }
      calculate_statuses
    end
  end
end
