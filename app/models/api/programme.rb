require 'ostruct'

module Api
  module Generator
    module Programme
      def self.edition_to_hash(edition)
        attrs = edition.programme.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :alternative_title, :overview]))
        attrs['parts'] = edition.parts.sort_by(&:order).collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
        attrs['type'] = 'programme'
        attrs
      end
    end

  end

  module Client
    class Programme < OpenStruct
      def self.from_hash(hash)
        programme = new(hash)
        programme.parts = programme.parts.collect { |p| Part.from_hash(p) }.sort_by {|p| p.order }
        programme
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

      class Part < OpenStruct
        def self.from_hash(hash)
          new(hash)
        end
      end
    end
  end
end

