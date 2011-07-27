require 'ostruct'

module Api
  module Generator
    def self.edition_to_hash(edition)
      case edition.container.class.to_s
        when 'Transaction' then Api::Generator::Transaction.edition_to_hash(edition)
        when 'Guide' then Api::Generator::Guide.edition_to_hash(edition)
        when 'Answer' then Api::Generator::Guide.edition_to_hash(edition)
      end
    end

    module Guide
      def self.edition_to_hash(edition)
        attrs = edition.guide.as_json(:only => [:audiences, :slug, :tags, :updated_at])
        attrs.merge!(edition.as_json(:only => [:title]))
        attrs['parts'] = edition.parts.collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
        attrs['type'] = 'guide'
        attrs
      end
    end

    module Answer
      def self.edition_to_hash(edition)
        attrs = edition.answer.as_json(:only => [:audiences, :slug, :tags, :updated_at])
        attrs['type'] = 'answer'
        attrs.merge!(edition.as_json(:only => [:title,:body]))
      end
    end
    
    module Transaction
      def self.edition_to_hash(edition)
        attrs = edition.transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at])
        attrs['type'] = 'transaction'
        attrs.merge!(edition.as_json(:only => [:title,:introduction,:more_information,:will_continue_on,:link]))
      end
    end
    
  end

  module Client
    def self.from_hash(response)
      case response['type']
      when 'guide' then Api::Client::Guide.from_hash(response)
      when 'transaction' then Api::Client::Transaction.from_hash(response)
      when 'answer' then Api::Client::Answer.from_hash(response)
      end
    end
    
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
    end

    class Part < OpenStruct
      def self.from_hash(hash)
        new(hash)
      end
    end
  end
end