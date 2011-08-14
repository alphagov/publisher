require 'active_support/inflector'

require 'api/guide'
require 'api/place'
require 'api/local_transaction'

module Api
  module Generator
    def self.generator_class(edition)
      "Api::Generator::#{edition.container.class.to_s}".constantize
    end

    def self.edition_to_hash(edition, *args)
      generator_class(edition).edition_to_hash(edition, *args)
    end
  end
end
