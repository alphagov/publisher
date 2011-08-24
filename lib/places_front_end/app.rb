require 'net/http'
require 'api/generator'
require 'api/client'

module PlacesFrontEnd
  class App < PlacesFrontEnd::Base
    configure do
      case ENV['RACK_ENV']
        when ('development' or 'test')
          api_host = "local.alphagov.co.uk:3000"
          imminence_api_host = "local.alphagov.co.uk:3002"
        when 'production'
          api_host = "api.alpha.gov.uk"
          imminence_api_host = "imminence.alpha.gov.uk"
        else
          api_host = "guides.#{ENV['RACK_ENV']}.alphagov.co.uk:8080"
          imminence_api_host = "imminence.staging.alphagov.co.uk:8080"
      end
      set :api_host, api_host
      set :imminence_api_host, imminence_api_host
    end

    def fetch_publication
      url = URI.parse("http://#{settings.api_host}/publications/#{params[:slug]}.json")
      Net::HTTP.start(url.host, url.port) do |http|
        http.get(url.path)
      end
    end
    
    def publication_response
      @publication_response ||= fetch_publication
    end

    def publication_hash
      if publication_response.code.to_i == 200
        JSON.parse(@publication_response.body)
      end
    end

    def publication
      @publication ||= Api::Client.from_hash(publication_hash)
    end
  end
end