require 'active_support/inflector'

module Api

  module Generator
    def self.generator_class(edition)
      "Api::Generator::#{edition.container.class.to_s}".constantize
    end

    def self.edition_to_hash(edition, *args)
      generator_class(edition).edition_to_hash(edition, *args)
    end

     module Guide
      def self.edition_to_hash(edition,options={})
        attrs = edition.guide.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :alternative_title, :overview]))
        attrs['parts'] = edition.parts.sort_by(&:order).collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
        attrs['type'] = 'guide'
        attrs
      end
    end

    module Answer
      def self.edition_to_hash(edition,options={})
        attrs = edition.answer.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs['type'] = 'answer'
        attrs.merge!(edition.as_json(:only => [:title,:body, :alternative_title, :overview]))
      end
    end
    
    module Transaction
      def self.edition_to_hash(edition,options={})
        attrs = edition.transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs['type'] = 'transaction'
        attrs['expectations'] = edition.expectations.map {|e| e.as_json(:only => [:css_class,:text]) }
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :will_continue_on,:link, :alternative_title, :overview, :minutes_to_complete, :uses_government_gateway]))
      end
    end

    module LocalTransaction
      def self.edition_to_hash(edition, options = {})
        snac = options[:snac]
        all  = options[:all]
        attrs = edition.local_transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :alternative_title, :overview, :minutes_to_complete]))
        attrs['type'] = 'local_transaction'
        attrs['expectations'] = edition.expectations.map { |e| e.as_json(:only => [:css_class, :text]) }
        if snac
          attrs['authority'] = edition.local_transaction.lgsl.authorities.where(snac: snac).first.as_json(:only => [:snac, :name], :include => {:lgils => {:only => [:url, :code]}})
        elsif all
          attrs['authorities'] = edition.local_transaction.lgsl.authorities.all.as_json(:only => [:snac, :name], :include => {:lgils => {:only => [:url, :code]}})
        end
        attrs
      end
    end

    module Place
      def self.edition_to_hash(edition, options={})
        attrs = edition.place.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :place_type, :alternative_title, :overview]))
        attrs['expectations'] = edition.expectations.map {|e| e.as_json(:only => [:css_class,:text]) }
        attrs['type'] = 'place'
        attrs
      end
    end
    
    module Programme
      def self.edition_to_hash(edition,options={})
        attrs = edition.programme.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :alternative_title, :overview]))
        attrs['parts'] = edition.parts.sort_by(&:order).collect { |p| p.as_json(:only => [:slug, :title, :body]).merge('number' => p.order) }
        attrs['type'] = 'programme'
        attrs
      end
    end

  end
end
