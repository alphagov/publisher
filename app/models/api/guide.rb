require 'ostruct'

module Api
  module Generator
    module Guide
      def self.edition_to_hash(edition)
        attrs = edition.guide.as_json(:only => [:slug, :tags, :updated_at])
        attrs.merge!(edition.as_json(:only => [:title]))
        attrs['parts'] = edition.parts.collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
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

      def part_index(slug)
        parts.index { |p| p.slug == slug }
      end

      def find_part(slug)
        return nil unless index = part_index(slug)
        parts[index]
      end

      def part_after(part)
        return nil unless index = part_index(part.slug)
        next_index = index + 1
        return nil if next_index >= parts.length
        parts[next_index]
      end

      def has_previous_part?(part)
        index = part_index(part.slug)
        !index.nil? && index > 0 && true
      end

      def has_next_part?(part)
        index = part_index(part.slug)
        !index.nil? && (index + 1) < parts.length && true
      end

      def part_before(part)
        return nil unless index = part_index(part.slug)
        previous_index = index - 1
        return nil if previous_index < 0
        parts[previous_index]
      end
    end

    class Part < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
  end
end