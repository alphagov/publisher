require 'net/http'

module LocalTransactionsFrontEnd
  class App < LocalTransactionsFrontEnd::Base
    configure do
      case ENV['RACK_ENV']
        when ('development' or 'test')
          api_host = "local.alphagov.co.uk:3000"
        when 'production'
          api_host = "api.alpha.gov.uk"
        else
          api_host = "guides.#{ENV['RACK_ENV']}.alphagov.co.uk:8080"
      end
      set :api_host, api_host
    end

    def fetch_publication(snac = nil)
      if snac
        url = URI.parse("http://#{settings.api_host}/local_transactions/#{params[:slug]}/#{snac}.json")
      else
        url = URI.parse("http://#{settings.api_host}/local_transactions/#{params[:slug]}.json")
      end
      Net::HTTP.start(url.host, url.port) do |http|
        http.get(url.path)
      end
    end
    
    def publication_response(opts = {})
      @publication_response ||= fetch_publication(opts)
    end

    def publication_hash(opts = {})
      if publication_response(opts).code.to_i == 200
        JSON.parse(publication_response.body)
      end
    end

    def router
      if publication_response.code.to_i == 200
        return publication_hash['type'].to_sym
      else
        nil
      end
    end
  end
end