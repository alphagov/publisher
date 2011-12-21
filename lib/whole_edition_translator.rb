class Publication; 
  include Mongoid::Document
  field :panopticon_id, :type => Integer
  field :name, :type => String
  field :slug, :type => String
  field :section, :type => String
  field :department, :type => String
  field :rejected_count, :type => Integer, default: 0
  field :edition_rejected_count, :type => Integer, default: 0
end

class TransitionalEdition
  include Mongoid::Document
  include Expectant
  embeds_many :actions
  belongs_to :assigned_to, class_name: 'User'
end

class TransitionalAnswerEdition < TransitionalEdition
  embedded_in :answer
  alias :container :answer
end

class TransitionalTransactionEdition < TransitionalEdition
  embedded_in :transaction
  alias :container :transaction
end

class TransitionalGuideEdition < TransitionalEdition
  embedded_in :guide
  alias :container :guide
  embeds_many :parts, :class_name => 'Part'
end

class Answer < Publication
  embeds_many :editions, :class_name => 'TransitionalAnswerEdition'
end

class Guide < Publication
  embeds_many :editions, :class_name => 'TransitionalGuideEdition'
end

class Transaction < Publication
  embeds_many :editions, :class_name => 'TransitionalTransactionEdition'
end

class Place < Publication
  embeds_many :editions, :class_name => 'TransitionalPlaceEdition'
end

class TransitionalPlaceEdition < TransitionalEdition
  embedded_in :place
  alias :container :place
end

class Programme < Publication
  embeds_many :editions, :class_name => 'TransitionalProgrammeEdition'
end

class TransitionalProgrammeEdition < TransitionalEdition
  embedded_in :programme
  alias :container :programme
end

class LocalTransaction < Publication
  embeds_many :editions, :class_name => 'TransitionalLocalTransactionEdition'
end

class TransitionalLocalTransactionEdition < TransitionalEdition
  embedded_in :local_transaction
  alias :container :local_transaction
end

class WholeEditionTranslator
  attr_accessor :original_edition, :whole_edition
  
  def initialize(original_edition)
    self.original_edition = original_edition
  end
  
  def build_whole_edition
    basic_attributes = { _type: "#{original_edition.container.class}Edition" }
    publication = original_edition.container
    basic_attributes.merge!(slug: publication.slug, panopticon_id: publication.panopticon_id)
    basic_attributes[:lgsl_code] = publication.lgsl_code if publication.respond_to?(:lgsl_code)
    
    full_attribute_set = basic_attributes.merge(original_edition.attributes)
    parts = full_attribute_set.delete(:parts) || {}
    klass = "#{publication.class}Edition".constantize
    self.whole_edition = klass.new(full_attribute_set)
    if parts.any?
      parts.each { |p| self.whole_edition.parts.build(p) }
    end
    self.whole_edition
  end

  def run
    build_whole_edition
  end
end