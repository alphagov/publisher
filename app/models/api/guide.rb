require 'ostruct'

module Api
  module Generator
    module Guide
      def self.edition_to_hash(edition)
        attrs = edition.guide.as_json(:only => [:audiences, :slug, :tags, :updated_at, :category, :related_items])
        attrs.merge!(edition.as_json(:only => [:title]))
        attrs['parts'] = edition.parts.sort_by(&:order).collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
        attrs['type'] = 'guide'
        attrs
      end
    end

    module Answer
      def self.edition_to_hash(edition)
        attrs = edition.answer.as_json(:only => [:audiences, :slug, :tags, :updated_at, :category, :related_items])
        attrs['type'] = 'answer'
        attrs.merge!(edition.as_json(:only => [:title,:body]))
      end
    end
    
    module Transaction
      def self.edition_to_hash(edition)
        attrs = edition.transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at, :category, :related_items])
        attrs['type'] = 'transaction'
        attrs['expectations'] = edition.expectations.map {|e| e.as_json(:only => [:css_class,:text]) }
        attrs.merge!(edition.as_json(:only => [:title,:introduction,:more_information,:will_continue_on,:link]))
      end
    end
    
  end

  module Client
    class Answer < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
    
    class Transaction < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
    
    class Guide < OpenStruct
      def self.from_hash(hash)
        guide = new(hash)
        guide.parts = guide.parts.collect { |p| Part.from_hash(p) }.sort_by {|p| p.order }
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

      class Part < OpenStruct
        def self.from_hash(hash)
          new(hash)
        end
      end
    end
  end
end
