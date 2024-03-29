class PublishingApiProxyController < ApplicationController
  def lookup_by_base_path
    content_id = Services.publishing_api.lookup_content_id(base_path: params[:base_path])

    if content_id.present?
      render json: { content_id: }
    else
      render json: {}, status: :not_found
    end
  end
end
