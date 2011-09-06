require 'sinatra'
require 'erubis'
require 'json'

module PlacesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/places_front_end', __FILE__)
    set :public, File.expand_path('../../../public', __FILE__)

    include Rack::Geo::Utils

    helpers do
      def geo_known_to_at_least?(accuracy)
        options = ['point', 'postcode', 'postcode_district', 'ward', 'council', 'nation', 'country', 'planet']
        the_index = options.index(accuracy.to_s)
        geo_known_to?(*options.slice(0, the_index + 1))
      end

      def geo_known_to?(*accuracy)
        geo_header and geo_header['fuzzy_point'] and accuracy.include?(geo_header['fuzzy_point']['accuracy'])
      end

      def geo_header
        if env['HTTP_X_GOVGEO_STACK'] and env['HTTP_X_GOVGEO_STACK'] != ''
          @geo_header ||= JSON.parse(Base64.decode64(env['HTTP_X_GOVGEO_STACK']))
          @geo_friendly_name = @geo_header['friendly_name']
          @district_postcode = @geo_header['postcode'] if @geo_header['postcode'].present?
        end
        @geo_header
      end

      def asset_host
        FrontEndEnvironment.asset_host
      end

      def base_path(guide_slug)
        "/#{guide_slug}"
      end

      def reset_geo_url
        callback = Addressable::URI.parse(request.url)
        callback.query_values = {:reset_geo => 'true'}
        return callback.to_s
      end

      def partial(page, options={})
        erubis page, options.merge!(:layout => false)
      end

      def mustache_partial(page, options)
        file_path = File.join(settings.views, page + '.mustache')
        Mustache.render(File.read(file_path), options)
      end
    end

    def get_options(type, lon, lat, limit = 5)
      url = "http://#{settings.imminence_api_host}/places/#{type}.json?limit=#{limit}&lat=#{lat}&lng=#{lon}"
      open(url).read
    end

    def setup_options
      if geo_known_to_at_least?('ward')
        options_data = get_options(publication.place_type, geo_header['fuzzy_point']['lon'], geo_header['fuzzy_point']['lat'])
        my_opts = JSON.parse(options_data)
        return my_opts.map do |o|
          o['latitude'] = o['location'][0]
          o['longitude'] = o['location'][1]
          o['address'] = [o['address1'], o['address2']].reject { |a| a.nil? or a == '' }.map { |a| a.strip }.join(', ')
          o
        end
    end

      return []
    end

    def show_place
      halt(404) if publication.nil? # 404 if place not found
      options = setup_options
      erubis :"place.html", :locals => {:place => publication, :options => options}
    end

    get '/places/:slug.json' do
      content_type :json
      if geo_known_to_at_least?('ward')
        return setup_options.to_json
      else
        return env['HTTP_X_GOVGEO_STACK'].to_json
      end
    end

    get '/places/:slug' do
      return show_place
    end

  end
end
