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

      def base_path(programme_slug, part_slug)
        "/#{programme_slug}/#{part_slug}"
      end
      
      def programme_path(programme_slug, part_slug)
        base_path(programme_slug,part_slug)
      end
    end
    
    get '/:slug/:part_slug' do
      halt(404) if publication.nil? # 404 if guide not found
      part = publication.find_part(params[:part_slug])
      halt(404) if part.nil? # 404 if part not found
      erubis :"programme.html", :locals => {:programme => publication, :part => part}
    end
        
    get '/:slug' do
      route = router
      halt(404) if route.nil? 
      case route
        when :programme
          if publication.parts.any? and publication.parts.first.slug and publication.parts.first.slug != ''
            redirect to(base_path(params[:slug], publication.parts.first.slug))
          else
            halt(404)
          end
        when :answer
          erubis :"answer.html", :locals => {:answer => publication}
        when :transaction
          erubis :"transaction.html", :locals => {:transaction => publication}
      end
    end
  end
end
