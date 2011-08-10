require 'active_support/inflector'

require 'api/guide'
require 'api/local_transaction'

module Api
  module Generator
    def self.edition_to_hash(edition)
      "Api::Generator::#{edition.container.class.to_s}".constantize.edition_to_hash(edition)
    end
  end
end
