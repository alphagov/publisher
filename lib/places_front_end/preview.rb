# require File.expand_path('../../../app/models/api/guide', __FILE__)
require 'api/generator'
require 'api/client'

module PlacesFrontEnd
  class Preview < PlacesFrontEnd::Base
    configure do
      set :imminence_api_host, FrontEndEnvironment.imminence_api_host
    end

    def self.preview_edition_id(env)
      env['action_dispatch.request.path_parameters'][:edition_id]
    end

    def preview_edition_id
      self.class.preview_edition_id(request.env)
    end

    def get_publication
      @this_publication ||= Publication.where(:slug => params[:slug]).first
    end

    def setup_publication
      publication = get_publication.editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      hashed_publication = Api::Generator.edition_to_hash(publication)
      Api::Client.from_hash(hashed_publication)
    end

    def publication
      @publication ||= setup_publication
    end
  end
end
