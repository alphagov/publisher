require File.expand_path('../../../app/models/api/guide', __FILE__)
module LocalTransactionsFrontEnd
  class Preview < LocalTransactionsFrontEnd::Base
    def self.preview_edition_id(env)
      env['action_dispatch.request.path_parameters'][:edition_id]
    end

    def preview_edition_id
      self.class.preview_edition_id(request.env)
    end

    def get_publication
      LocalTransaction.where(:slug => params[:slug]).first
    end

    def get_edition
      get_publication.editions.select { |e| e.version_number.to_i == preview_edition_id.to_i }.first
    end

    def publication_hash(*args)
      publication = get_edition
      Api::Generator.edition_to_hash(publication, *args)
    end

    def provider_snac_code(snac_codes)
      snac_codes.each do |snac|
        return snac if get_publication.verify_snac(snac)
      end
      return nil
    end
  end
end
