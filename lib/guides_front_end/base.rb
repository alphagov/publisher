require 'sinatra'
require 'erubis'

module GuidesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/guides_front_end', __FILE__)
    set :public, File.expand_path('../../../public', __FILE__)
   
    helpers do
      def asset_host
        FrontEndEnvironment.asset_host
      end

      def base_path(guide_slug, part_slug)
        "/#{guide_slug}/#{part_slug}"
      end
      
      def guide_path(guide_slug, part_slug)
        base_path(guide_slug,part_slug)
      end
    end
    
    get '/:slug/:part_slug' do
      halt(404) if publication.nil? # 404 if guide not found
      part = publication.find_part(params[:part_slug])
      halt(404) if part.nil? # 404 if part not found
      erubis :"guide.html", :locals => {:guide => publication, :part => part}
    end
        
    get '/:slug' do
      route = router
      halt(404) if route.nil? 
      case route
        when :guide
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
