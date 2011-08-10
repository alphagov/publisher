require 'active_support/inflector'

require 'api/guide'
require 'api/local_transaction'

module Api
  module Client
    def self.from_hash(response)
      "Api::Client::#{response['type'].classify}".constantize.from_hash(response)
      if response.updated_at.class == String
        response.updated_at = Time.parse(response.updated_at)
      end
      response
    end
  end
end