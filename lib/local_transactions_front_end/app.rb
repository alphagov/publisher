require 'net/http'

module LocalTransactionsFrontEnd
  class App < LocalTransactionsFrontEnd::Base
    configure do
      set :api_host, FrontEndEnvironment.api_host
    end

    def fetch_publication(snac = nil)
      if !snac.nil? && !snac.empty?
        url = URI.parse("http://#{settings.api_host}/local_transactions/#{params[:slug]}/#{snac}.json")
      else
        url = URI.parse("http://#{settings.api_host}/local_transactions/#{params[:slug]}.json")
      end
      Net::HTTP.start(url.host, url.port) do |http|
        http.get(url.path)
      end
    end

    def provider_snac_code(snac_codes)
      url = URI.parse("http://#{settings.api_host}/local_transactions/#{params[:slug]}/verify_snac.json")
      Net::HTTP.start(url.host, url.port) do |http|
        post_response = http.post(url.path, {'snac_codes' => snac_codes}.to_json, {'Content-Type' => 'application/json'})
        if post_response.code == '200'
          return JSON.parse(post_response.body)['snac']
        end
      end
      return nil
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
