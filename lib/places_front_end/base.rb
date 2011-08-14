require 'sinatra'
require 'erubis'

module PlacesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/places_front_end', __FILE__)
    set :public, File.expand_path('../../../public', __FILE__)
   
    include Rack::Geo::Utils

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

      def partial(page, options={})
        erubis page, options.merge!(:layout => false)
      end
    end

    def get_options(type, lon, lat, limit = 5)
      url = "http://#{settings.imminence_api_host}/places/#{type}.json?limit=#{limit}&lat=#{lat}&lng=#{lon}"
      response = open(url).read
      JSON.parse(response)
    end
    
    def show_place
      halt(404) if publication.nil? # 404 if place not found
      
      if env['HTTP_X_GOVGEO_STACK'] and env['HTTP_X_GOVGEO_STACK'] != ''
        location_data = decode_stack(env['HTTP_X_GOVGEO_STACK'])
        if location_data['fuzzy_point'] and location_data['fuzzy_point']['accuracy'] != 'planet'
          options = get_options(publication.place_type, location_data['fuzzy_point']['lon'], location_data['fuzzy_point']['lat'])
        end        
      end
      
      options ||= []
      
      erubis :"place.html", :locals => {:place => publication, :options => options}
    end
    
    get '/places/:slug' do
      return show_place
    end
    
    get '/:slug' do
      return show_place
    end
  end
end
