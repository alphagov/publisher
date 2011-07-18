module GuidesFrontEnd
  class Preview < GuidesFrontEnd::Base
    def self.preview_edition_id(env)
      env['action_dispatch.request.path_parameters'][:edition_id]
    end
    
    def preview_edition_id
      self.class.preview_edition_id(request.env)
    end

    def guide
      edition = Guide.where(:slug => params[:slug]).first.editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      Api::Client::Guide.from_hash(Api::Generator::Guide.edition_to_hash(edition))
    end
  end
end
