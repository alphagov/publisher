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
    
    def get_guide(slug)
      Guide.where(:slug => slug).first
    end
    
    def get_answer(slug)
      Answer.where(:slug => slug).first
    end
    
    def get_transaction(slug)
      Transaction.where(:slug => slug).first
    end
    
    def router(slug)
      if get_guide(slug)
        :guide
      elsif get_answer(slug)
        :answer
      elsif get_transaction(slug)
        :transaction
      else
        nil
      end
    end

    def transaction
      transaction = get_transaction(params[:slug]).editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      Api::Client::Transaction.from_hash(Api::Generator::Transaction.edition_to_hash(transaction))
    end

    def answer
      answer = get_answer(params[:slug]).editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      Api::Client::Answer.from_hash(Api::Generator::Answer.edition_to_hash(answer))
    end

    def guide
      edition = get_guide(params[:slug]).editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
      Api::Client::Guide.from_hash(Api::Generator::Guide.edition_to_hash(edition))
    end
  end
end
