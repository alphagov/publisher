class ServiceSignInController < ApplicationController
  def index
    @resources = ServiceSignInEdition.all
  end

  def show
    @resource = ServiceSignInEdition.find_by(slug: params[:slug])
  end
end
