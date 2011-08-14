require 'sinatra'
require 'erubis'

module LocalTransactionsFrontEnd
  class Base < Sinatra::Base
    set :views, File.expand_path('../../../app/views/local_transactions_front_end', __FILE__)
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

      def publication_path(slug)
        base_path(slug)
      end

      def base_path(slug)
        "/#{slug}"
      end
    end

    get '/:slug' do
      halt(404) if publication.nil? # 404 if transaction not found
      erubis :"show.html", :locals => {:local_transaction => publication}
    end
        
    post '/:slug' do
      halt(404) if publication.nil? # 404 if transaction not found
    end

    get '/:slug/:snac' do
      halt(404) if publication(params[:snac]).nil? # 404 if transaction not found
      erubis :"result.html", :locals => {:local_transaction => publication}
    end

    def publication(*args)
      @publication ||= Api::Client.from_hash(publication_hash(*args))
    end
  end
end
