require 'sinatra'
require 'erubis'

module ProgrammesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/programmes_front_end', __FILE__)
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

      def partial (template, locals = {})
        erubis template, :layout => false, :locals => locals
      end

      def base_path(programme_slug, part_slug=nil)
        "/#{programme_slug}/#{part_slug}"
      end

      def programme_path(programme_slug, part_slug=nil)
        base_path(programme_slug, part_slug)
      end
    end

    get '/:slug/further-information' do
      halt(404) if publication.nil? # 404 if guide not found
      part = publication.find_part('further-information')
      halt(404) if part.nil? # 404 if part not found
      erubis :"programme.html", :locals => {:programme => publication, :part => part, :is_overview => false}
    end

    get '/:slug' do
      route = router
      halt(404) if route.nil?
      erubis :"programme.html", :locals => {:programme => publication, :part => publication.parts.first, :is_overview => true}
    end
  end
end
