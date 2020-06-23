class Edition
  class Tab
    TABS = %w[edit tagging metadata history admin related_external_links unpublish].freeze
    attr_accessor :name

    def initialize(name = nil)
      @name = name
    end

    def self.all
      @all ||= TABS.map { |name| Tab.new(name) }
    end

    def self.[](name)
      Tab.new(name)
    end

    def title
      case name
      when "history"
        "History and notes"
      when "related_external_links"
        "Related external links"
      else
        name.capitalize
      end
    end

    def path(edition_path)
      name == "edit" ? edition_path : "#{edition_path}/#{name}"
    end

    def ==(other)
      name == other.name
    end
  end
end
