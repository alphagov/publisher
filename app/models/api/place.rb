require 'ostruct'

module Api
  module Generator
    module Place
      def self.edition_to_hash(edition)
        attrs = edition.place.as_json(:only => [:audiences, :slug, :tags, :updated_at, :category, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :place_type]))
        attrs['expectations'] = edition.expectations.map {|e| e.as_json(:only => [:css_class,:text]) }
        attrs['type'] = 'place'
        attrs
      end
    end
  end
  
  module Client
    class Place < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
  end
end