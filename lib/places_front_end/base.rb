require 'sinatra'
require 'erubis'

module PlacesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/places_front_end', __FILE__)
    set :public, File.expand_path('../../../public', __FILE__)
   
    helpers do
      def asset_host
        case ENV['RACK_ENV']
          when ('development' or 'test')
            ""
          when 'production'
            "http://alpha.gov.uk"
          else
            "http://#{ENV['RACK_ENV']}.alphagov.co.uk:8080"
        end
      end

      def base_path(guide_slug)
        "/#{guide_slug}"
      end
    end
    
    get '/places/:slug' do
      halt(404) if publication.nil? # 404 if place not found
      erubis :"place.html", :locals => {:place => publication}
    end
  end
end
