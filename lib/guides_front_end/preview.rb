require File.expand_path('../../../app/models/api/guide', __FILE__)
module GuidesFrontEnd
  class Preview < GuidesFrontEnd::Base
    def self.preview_edition_id(env)
      env['action_dispatch.request.path_parameters'][:edition_id]
    end

    helpers do
      def guide_path(guide_slug, part_slug)
        "/preview/#{preview_edition_id}#{base_path(guide_slug,part_slug)}"
      end
    end

    def preview_edition_id
      self.class.preview_edition_id(request.env)
    end

    def get_publication
      @this_publication ||= Publication.where(:slug => params[:slug]).first
    end

    def router
      publication = get_publication
      if publication
        publication.class.to_s.underscore.to_sym
      else
        nil
      end
    end

    def setup_publication
      publication = get_publication.editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      hashed_publication = Api::Generator.edition_to_hash(publication)
      Api::Client.from_hash(hashed_publication)
    end

    def publication
      @publication ||= setup_publication
    end
  end
end
