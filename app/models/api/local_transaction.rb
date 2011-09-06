module Api
  module Generator
    module LocalTransaction
      def self.edition_to_hash(edition, snac = nil)
        attrs = edition.local_transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :alternative_title, :overview, :minutes_to_complete]))
        attrs['type'] = 'local_transaction'
        attrs['expectations'] = edition.expectations.map { |e| e.as_json(:only => [:css_class, :text]) }
        if snac
          attrs['authority'] = edition.local_transaction.lgsl.authorities.where(snac: snac).first.as_json(:only => [:snac, :name], :include => {:lgils => {:only => [:url, :code]}})
        end
        attrs
      end
      
      def self.edition_to_hash_with_data(edition)
        attrs = edition.local_transaction.as_json(:only => [:audiences, :slug, :tags, :updated_at, :section, :related_items])
        attrs.merge!(edition.as_json(:only => [:title, :introduction, :more_information, :alternative_title, :overview]))
        attrs['type'] = 'local_transaction'
        attrs['expectations'] = edition.expectations.map { |e| e.as_json(:only => [:css_class, :text]) }
        attrs['authorities'] = edition.local_transaction.lgsl.authorities.all.as_json(:only => [:snac, :name], :include => {:lgils => {:only => [:url, :code]}})
        attrs
      end
    end
  end
  module Client
    class LocalTransaction < OpenStruct
      def self.from_hash(hash)
        hash['expectations'].collect! { |e| Expectation.from_hash(e) } if hash.has_key?('expectations')
        hash['authority'] = Authority.from_hash(hash['authority']) if hash.has_key?('authority')
        new(hash)
      end

      class Expectation < OpenStruct
        def self.from_hash(hash)
          new(hash)
        end
      end

      class Authority < OpenStruct
        def self.from_hash(hash)
          hash['lgils'].collect! { |l| Lgil.from_hash(l) } if hash.has_key?('lgils')
          new(hash)
        end

        class Lgil < OpenStruct
          def self.from_hash(hash)
            new(hash)
          end
        end
      end
    end
  end
end
