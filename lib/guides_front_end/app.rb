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

    def guide
      response = HTTParty.get("http://#{settings.api_host}/guides/#{params[:slug]}.json").to_hash
      Api::Client::Guide.from_hash(response)
    end
  end
end