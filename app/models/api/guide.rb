require 'ostruct'

module Api
  module Generator
    module Guide
      def self.edition_to_hash(edition)
        attrs = edition.guide.as_json(:only => [:slug, :tags])
        attrs.merge!(edition.as_json(:only => [:title, :introduction]))
        attrs['parts'] = edition.parts.collect { |p| p.as_json(:only => [:slug, :title, :body, :excerpt]).merge('number' => p.order) }
        attrs
      end
    end
  end

  module Client
    class Guide < OpenStruct
      def self.from_hash(hash)
        guide = new(hash)
        guide.parts = guide.parts.collect { |p| Part.from_hash(p) }
        guide
      end
    end

    class Part < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
  end
end