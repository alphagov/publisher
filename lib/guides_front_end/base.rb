require 'sinatra'
require 'erubis'

module GuidesFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/guides_front_end', __FILE__)
    set :public, File.expand_path('../../../public', __FILE__)

    def guide
      raise NotImplementedError, "#guide must be implemented by subclasses! It should return an Api::Client::Guide instance"
    end
    
    helpers do
      def guide_path(guide_slug, part_slug)
        "/#{guide_slug}/#{part_slug}"
      end
    end

    get '/:slug/:part_slug' do
      halt(404) if guide.nil? # 404 if guide not found
      part = guide.find_part(params[:part_slug])
      halt(404) if part.nil? # 404 if part not found
      erubis :"guide.html", :locals => {:guide => guide, :part => part}
    end

    get '/:slug' do
      halt(404) if guide.nil? # 404 if guide not found
      redirect to(guide_path(params[:slug], guide.parts.first.slug))
    end
  end
end
