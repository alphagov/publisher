module GuidesFrontEnd
  class App < GuidesFrontEnd::Base
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

    def guide_response(slug)
      HTTParty.get("http://#{settings.api_host}/guides/#{slug}.json")
    end

    def answer_response(slug)
      HTTParty.get("http://#{settings.api_host}/answers/#{slug}.json")
    end
    
     def transaction_response(slug)
        HTTParty.get("http://#{settings.api_host}/transaction/#{slug}.json")
      end

    def router(slug)
      if guide_response(slug).code == 200
        :guide
      elsif answer_response(slug).code == 200
        :answer
      elsif transaction_response(slug).code == 200
        :transaction
      else
        nil
      end
    end

    def transaction
       response = transaction_response(params[:slug]).to_hash
       Api::Client::Transaction.from_hash(response)
    end

    def answer
      response = answer_response(params[:slug]).to_hash
      Api::Client::Answer.from_hash(response)
    end

    def guide
      response = guide_response(params[:slug]).to_hash
      Api::Client::Guide.from_hash(response)
    end
  end
end