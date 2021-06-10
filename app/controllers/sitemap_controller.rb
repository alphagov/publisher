class SitemapController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def index
    @paths = Edition.published.flat_map(&:paths)
    respond_to { |format| format.xml }
  end
end
