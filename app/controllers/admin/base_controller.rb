class Admin::BaseController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'

  rescue_from Mongoid::Errors::DocumentNotFound, :with => :record_not_found
  
  def index
    redirect_to admin_root_url
  end
  
  protected
    def record_not_found
      render :text => "404 Not Found", :status => 404
    end
end
