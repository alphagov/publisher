require 'active_support/inflector'

module Api
  module Generator
    def self.generator_class(edition)
      "Api::Generator::#{edition.format}".constantize
    end

    def self.edition_to_hash(edition, *args)
      generator = generator_class(edition)
      edition_fields     =  [:slug, :updated_at, :title, :alternative_title, :overview] + generator.extra_fields

      attrs = edition.as_json(:only => edition_fields)

      if edition.respond_to?(:parts)
        non_blank_parts = []
        edition.parts.each do |part|
          non_blank_parts << part unless part.body.blank?
        end
        attrs['parts'] = non_blank_parts.sort_by(&:order).collect { |p| p.as_json(:only => [:slug, :title, :body]) }
      end

      if edition.respond_to?(:expectations)
        attrs['expectations'] = edition.expectations.map {|e| e.as_json(:only => [:css_class,:text]) }
      end

      attrs['type'] = edition.format.underscore
      generator.edition_to_hash(attrs, edition,*args)
    end

    class Base
      def self.extra_fields
        []
      end

      def self.edition_to_hash(attrs, guide, options={})
        attrs
      end
    end

    class Guide < Base
      def self.extra_fields
        [ :video_url,
          :video_summary]
      end
    end

    class BusinessSupport < Base
      def self.extra_fields
        [ :short_description, :min_value, :max_value ]
      end
    end

    class Programme < Base
    end

    class Licence < Base
      def self.extra_fields
        [ :licence_identifier,
          :licence_short_description,
          :licence_overview ]
      end
    end

    class Answer < Base
      def self.extra_fields
        [:body]
      end
    end

    class Transaction < Base
      def self.extra_fields
        [ :introduction,
          :more_information,
          :will_continue_on,
          :link,
          :minutes_to_complete,
          :uses_government_gateway,
          :alternate_methods]
      end
    end

    class LocalTransaction < Base
      def self.extra_fields
        [ :introduction,
          :more_information,
          :minutes_to_complete]
      end

      def self.authority_to_json(authority)
        return nil unless authority
        authority.as_json(only: [:name, :snac, :tier, :contact_address, :contact_url, :contact_phone, :contact_email])
      end

      def self.interaction_to_json(interaction)
        return nil unless interaction
        json = interaction.as_json(:only => [:lgsl_code, :lgil_code, :url])
        only = [:snac, :name, :tier, :contact_address, :contact_url, :contact_phone, :contact_email]
        # DEPRECATED: This is now located at the top level.
        json['authority'] = interaction.local_authority.as_json(:only => only)
        json
      end

      def self.edition_to_hash(attrs, edition, options = {})
        if options[:snac]
          service = edition.service

          interaction = service.preferred_interaction(options[:snac], edition.lgil_override)
          attrs['interaction'] = interaction_to_json(interaction)

          authority = service.preferred_provider(options[:snac])
          attrs['authority']   = authority_to_json(authority)
        end
        attrs
      end
    end

    class Place < Base
      def self.extra_fields
        [ :introduction,
          :more_information,
          :place_type]
      end
    end

    class Video < Base
      def self.extra_fields
        [ :video_url,
          :video_summary]
      end
    end
  end
end
